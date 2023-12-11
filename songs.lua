
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
local selection = 1
local leftHeldFor = 0 -- a measurement in ticks of how long left has been held
local rightHeldFor = 0 -- a measurement in ticks of how long right has been held

local albumArt = gfx.image.new(64, 64)

-- Song variables
currentSong = songList[1]
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


local function resetAnimationValues()
    delta = 0
    songBarCurrentY = 1000
    songBarTargetY = 800
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

        if leftPressed or leftHeldFor > 15 then
            selection = math.max(1, math.min(selection-1, #songList))
        end
        if rightPressed or rightHeldFor > 15 then
            selection = math.max(1, math.min(selection+1, #songList))
        end
        print(selection)
        
        if upPressed then
            -- test code to automatically start the first song
            local bpm = currentSong.bpm
            local musicFile = "songs/"..currentSong.name.."/"..currentSong.name
            local songTablePath = "songs/"..currentSong.name.."/"..currentDifficulty..".json"
            local beatOffset = currentSong.beatOffset
            setUpSong(bpm, beatOffset, musicFile, songTablePath)
            resetAnimationValues()
            return "song"
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
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(screenCenterX, songBarCurrentY, 600)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(5)
    gfx.drawArc(screenCenterX, songBarCurrentY, 600, -20, 20)


    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("Press up to start test song: "..currentSong.name..", "..currentDifficulty, 2, 2, fonts.orbeatsSans)

    -- Get and draw the current selection's high score
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

    -- draw album art
    -- draw the shadow
    gfx.setColor(gfx.kColorBlack)
    gfx.fillEllipseInRect(screenCenterX-36, songBarCurrentY-584, 72, 16)
    local albumArtFilePath = "songs/"..currentSongList[math.floor(selection)].name.."/albumArt.pdi"
    local missingArt = "sprites/missingArt"
    print(albumArtFilePath)
    if pd.file.exists(albumArtFilePath) then
        albumArt:load(albumArtFilePath)
    else
        albumArt:load(missingArt)
    end
    albumArt:draw(screenCenterX-32, songBarCurrentY-640)

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