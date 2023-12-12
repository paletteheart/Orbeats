
import "game"

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterX <const> = screenWidth / 2
local screenCenterY <const> = screenHeight / 2

local function getListOfSongs()
    local songFolders = pd.file.listFiles("/songs/")

    for i=#songFolders,1,-1 do
        if songFolders[i]:sub(-1) ~= '/' then
            table.remove(songFolders, i)
        elseif not pd.file.exists("songs/"..songFolders[i].."songData.json") then
            table.remove(songFolders, i)
            print("removed")
        end
    end

    local songList = {}
    for i=#songFolders,1,-1 do
        local songData = json.decodeFile(pd.file.open("songs/"..songFolders[i].."songData.json"))
        table.insert(songList, songData)
    end

    return songList
end

local songList <const> = getListOfSongs()

local function sortSongListByName()
    local sortedList = {}
    for i, v in ipairs(songList) do
        sortedList[i] = v  -- Copy original table's content to the new table
    end
    table.sort(sortedList, function(a, b)
        return a.name < b.name
    end)
    return sortedList
end
local function sortSongListByArtist()
    local sortedList = {}
    for i, v in ipairs(songList) do
        sortedList[i] = v  -- Copy original table's content to the new table
    end
    table.sort(sortedList, function(a, b)
        if a.artist ~= b.artist then
            return a.artist < b.artist
        else
            return a.name < b.name
        end
    end)
    return sortedList
end

local songListSortedByName <const> = sortSongListByName()
local songListSortedByArtist <const> = sortSongListByArtist()

-- Define variables
-- Misc variables
scores = json.decodeFile(pd.file.open("scores.json"))
sortBy = ""
sortSongs = true
currentSongList = songListSortedByArtist
local songSelection = 1
local songSelectionRounded = songSelection
local mapSelection = 1
local mapSelectionRounded = mapSelection
local leftHeldFor = 0 -- a measurement in ticks of how long left has been held
local rightHeldFor = 0 -- a measurement in ticks of how long right has been held
local selectingMap = false

local songBarSprite = gfx.image.new("sprites/songBar")

-- Song variables
currentSong = currentSongList[1]
currentDifficulty = currentSong.difficulties[1]
songTable = {}

-- Reset high scores variables
resetHiScores = false
local warningCurrentY = -45
warningTargetY = 5

-- Animation variables
local delta = 0
local sheenDuration = 600
local songBarCurrentY = 1000
local songBarTargetY = 800
local songBarRadius = 600
local selectBarCurrentY = -25
local selectBarTargetY = 0


local function resetAnimationValues()
    delta = 0
    songBarCurrentY = 1000
    songBarTargetY = 800
    selectBarCurrentY = -25
    selectBarTargetY = 0
    selectingMap = false
end

local function round(number)
    local integralPart = math.floor(number)
    local fractionalPart = number - integralPart

    if fractionalPart == 0.5 then
        -- Check if the integral part is even
        if integralPart % 2 == 0 then
            return integralPart  -- Round to the nearest even number
        else
            return math.floor(number + 0.5)  -- Round up for odd integral part
        end
    else
        return math.floor(number + 0.5)  -- Round normally for other cases
    end
end

local imageCache = {}
local function getImage(path)
    if imageCache[path] == nil then
        imageCache[path] = gfx.image.new(path)
    end
    return imageCache[path]
end

function updateSongSelect()
    -- update delta
    delta += 1

    -- update how long left and right has been held
    if leftHeld then
        leftHeldFor += 1
    else
        leftHeldFor = 0
    end
    if rightHeld then
        rightHeldFor += 1
    else
        rightHeldFor = 0
    end

    

    -- make sure we're not in the reset high scores menu
    if not resetHiScores then
        -- update the song songSelection based on cranking and left/right presses
        if leftPressed or leftHeldFor > 15 then
            songSelection = round(songSelection)-0.51
        end
        if rightPressed or rightHeldFor > 15 then
            songSelection = round(songSelection)+0.51
        end
        songSelection += crankChange/30
        -- move the songSelection to the nearest integer if not moving the crank or if past the edge of the list
        if math.abs(crankChange) < 0.5 or songSelection > #songList or songSelection < 1 then
            songSelection = closeDistance(songSelection, math.min(#songList, math.max(1, round(songSelection))), 0.5)
        end
        -- round the songSelection for things that need the exact songSelection
        songSelectionRounded = math.min(#songList, math.max(1, round(songSelection)))

        -- update the current song
        currentSong = currentSongList[songSelectionRounded]
        
        if upPressed or aPressed then
            if selectingMap then
                -- test code to automatically start the first song
                local bpm = currentSong.bpm
                local musicFile = "songs/"..currentSong.name.."/"..currentSong.name
                local songTablePath = "songs/"..currentSong.name.."/"..currentDifficulty..".json"
                local beatOffset = currentSong.beatOffset
                setUpSong(bpm, beatOffset, musicFile, songTablePath)
                resetAnimationValues()
                return "song"
            else
                selectBarCurrentY = -25
                selectingMap = true
            end
        end

        if downPressed or bPressed then
            if selectingMap then
                selectingMap = false
                selectBarCurrentY = -25
            end
        end

        if selectingMap then
            songBarTargetY = 832
        else
            songBarTargetY = 800
        end
    
        
    else -- if we are in the reset menu
        if upHeld and aHeld then
            pd.datastore.write({}, "scores")
            scores = json.decodeFile(pd.file.open("scores.json"))
            warningTargetY = -45
        elseif downPressed or bPressed then
            warningTargetY = -45
        end
        if warningTargetY == -45 and warningCurrentY == -45 then
            resetHiScores = false
        end
    end

    -- sort the song list if the sorting method has changed
    if sortSongs then
        if sortBy == "artist" then
            currentSongList = songListSortedByArtist
        else
            currentSongList = songListSortedByName
        end
        sortSongs = false
    end
    

    return "songSelect"
end



function drawSongSelect()
    -- draw background sheen
    local sheenX = sheenDuration-(delta%(sheenDuration+(sheenDuration-400)))
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(0.5)
    gfx.setLineWidth(250)
    gfx.drawLine(sheenX, screenHeight+50, sheenX+30, -50)

    -- draw the song bar
    songBarCurrentY = closeDistance(songBarCurrentY, songBarTargetY, 0.3)
    -- gfx.setColor(gfx.kColorWhite)
    -- gfx.fillCircleAtPoint(screenCenterX, songBarCurrentY, songBarRadius)
    -- gfx.setColor(gfx.kColorBlack)
    -- gfx.setDitherPattern(2/3)
    -- gfx.fillCircleAtPoint(screenCenterX, songBarCurrentY, songBarRadius)
    -- gfx.setColor(gfx.kColorBlack)
    -- gfx.setLineWidth(5)
    -- gfx.drawArc(screenCenterX, songBarCurrentY, songBarRadius, -20, 20)
    songBarSprite:draw(0, songBarCurrentY-songBarRadius)


    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("Press up to start test song: "..currentSong.name..", "..currentDifficulty, 2, 2, fonts.orbeatsSans)

    -- Get and draw the current songSelection's high score
    local currentHiScore
    local currentBestRank
    if scores[currentSong.name] ~= nil then
        if scores[currentSong.name][currentDifficulty] ~= nil then
            currentHiScore = scores[currentSong.name][currentDifficulty].score
            currentBestRank = scores[currentSong.name][currentDifficulty].rating
        else
            currentHiScore = 0
            currentBestRank = "-"
        end
    else
        currentHiScore = 0
        currentBestRank = "-"
    end
    gfx.drawText("Best Score: "..currentHiScore.." Best Rating: "..currentBestRank, 2, 22, fonts.orbeatsSans)
    gfx.drawText("Artist: "..currentSong.artist.." BPM: "..currentSong.bpm, 2, 42, fonts.orbeatsSmall)


    -- draw the album art
    local missingArt = "sprites/missingArt"

    for i=songSelectionRounded+3,songSelectionRounded-3,-1 do
        if i <= #songList and i >= 1 then
            local albumArtFilePath = "songs/"..currentSongList[i].name.."/albumArt.pdi"

            local albumPos = -(songSelection-i)*8

            local albumX = screenCenterX + songBarRadius * math.cos(math.rad(albumPos-90)) - 32
            local albumY = songBarCurrentY + songBarRadius * math.sin(math.rad(albumPos-90)) - 32

            if pd.file.exists(albumArtFilePath) then
                getImage(albumArtFilePath):draw(albumX, albumY)
            else
                getImage(missingArt):draw(albumX, albumY)
            end
        end
    end
    

    -- draw menu controls
    local menuControlsY = 600 -- this is subtracted from the songBarCurrentY
    local controlsBubbleWidth = 50
    local controlsBubbleHeight = 26
    -- make the left controls bounce when you press left
    local bounce = 0
    if leftHeld then
        bounce = 2
    end
    -- draw the left controls bubble
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(0, songBarCurrentY-menuControlsY-4+bounce, controlsBubbleWidth, controlsBubbleHeight, 3)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawRoundRect(0, songBarCurrentY-menuControlsY-4+bounce, controlsBubbleWidth, controlsBubbleHeight, 3)
    gfx.drawText(char.left.."/"..char.ccw, 4, songBarCurrentY-menuControlsY+bounce, fonts.orbeatsSans)
    -- make the right controls bounce when you press right
    bounce = 0
    if rightHeld then
        bounce = 2
    end
    -- draw the right controls bubble
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(350, songBarCurrentY-menuControlsY-4+bounce, controlsBubbleWidth, controlsBubbleHeight, 3)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawRoundRect(350, songBarCurrentY-menuControlsY-4+bounce, controlsBubbleWidth, 26, 3)
    gfx.drawText(char.right.."/"..char.cw, 355, songBarCurrentY-menuControlsY+bounce, fonts.orbeatsSans)

    -- draw the up/down controls bar
    selectBarCurrentY = closeDistance(selectBarCurrentY, selectBarTargetY, 0.3)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, selectBarCurrentY, screenWidth, 25)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawLine(0, selectBarCurrentY+25, screenWidth, selectBarCurrentY+25)
    local selectControlText = ""
    if selectingMap then
        selectControlText = "Play:"..char.up.."/"..char.A.." --- Back:"..char.down.."/"..char.B.." --- "
    else
        selectControlText = "Confirm:"..char.up.."/"..char.A.." --- Confirm:"..char.up.."/"..char.A.." --- "
    end
    local selectTextWidth = gfx.getTextSize(selectControlText, fonts.orbeatsSans)
    local selectX1 = (delta % (selectTextWidth*3))-selectTextWidth
    local selectX2 = ((delta+selectTextWidth) % (selectTextWidth*3))-selectTextWidth
    local selectX3 = ((delta+(selectTextWidth*2)) % (selectTextWidth*3))-selectTextWidth
    gfx.drawText(selectControlText, selectX1, selectBarCurrentY+4, fonts.orbeatsSans)
    gfx.drawText(selectControlText, selectX2, selectBarCurrentY+4, fonts.orbeatsSans)
    gfx.drawText(selectControlText, selectX3, selectBarCurrentY+4, fonts.orbeatsSans)


    -- check if we're on the reset high scores menu
    if resetHiScores then
        -- draw the reset high scores menu
        -- draw background
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(0.5)
        gfx.fillRect(0, 0, screenWidth, screenHeight)

        -- draw bubble
        gfx.setColor(gfx.kColorWhite)
        local resetBubbleWidth = 200
        local resetBubbleHeight = 120
        local resetBubbleX = screenCenterX-(resetBubbleWidth/2)
        local resetBubbleY = screenCenterY-(resetBubbleHeight/2)
        gfx.fillRoundRect(resetBubbleX, resetBubbleY, resetBubbleWidth, resetBubbleHeight, 3)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(1)
        gfx.drawRoundRect(resetBubbleX, resetBubbleY, resetBubbleWidth, resetBubbleHeight, 3)

        -- draw text
        if warningCurrentY ~= warningTargetY then
            local change = (warningTargetY - warningCurrentY)*0.3
            warningCurrentY += math.floor(change)
        end
        gfx.drawText("WARNING!", screenCenterX-(gfx.getTextSize("WARNING!", fonts.odinRounded)/2), warningCurrentY, fonts.odinRounded)
        local textX = screenCenterX-(gfx.getTextSize("THIS WILL RESET ALL\nYOUR SCORES!", fonts.orbeatsSans)/2)
        gfx.drawText("THIS WILL RESET ALL\nYOUR SCORES!", textX, resetBubbleY+11, fonts.orbeatsSans)
        gfx.drawText("Press "..char.up.." and "..char.A.." to\nconfirm.", textX, resetBubbleY+51, fonts.orbeatsSans)
        gfx.drawText("Press "..char.down.."/"..char.B.." to cancel.", textX, resetBubbleY+91, fonts.orbeatsSans)

    end
end



function closeDistance(currentVal, targetVal, speed)
    local newVal = currentVal
    if currentVal ~= targetVal then
        local change = (targetVal - currentVal)*speed
        newVal = currentVal+change
    end
    return newVal
end