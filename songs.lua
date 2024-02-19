
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
local function sortSongListByBpm()
    local sortedList = {}
    for i, v in ipairs(songList) do
        sortedList[i] = v  -- Copy original table's content to the new table
    end
    table.sort(sortedList, function(a, b)
        return a.bpm < b.bpm
    end)
    return sortedList
end

local songListSortedByName <const> = sortSongListByName()
local songListSortedByArtist <const> = sortSongListByArtist()
local songListSortedByBpm <const> = sortSongListByBpm()

-- Define variables
-- Misc variables
scores = pd.datastore.read("scores")

settings = pd.datastore.read("settings")
tutorialPlayed = false
if settings ~= nil then
    if settings.tutorial ~= nil then tutorialPlayed = settings.tutorial end
    if settings.sfx ~= nil then playHitSfx = settings.sfx end
else
    settings = {}
end


local leftHeldFor = 0 -- a measurement in ticks of how long left has been held
local rightHeldFor = 0 -- a measurement in ticks of how long right has been held
local ticksSinceInput = 0
local selecting = "song"

local pointerSprite = gfx.image.new("sprites/pointer")

-- Audio Variables
sfx.low = pd.sound.sampleplayer.new("sfx/low")
sfx.mid = pd.sound.sampleplayer.new("sfx/mid")
sfx.high = pd.sound.sampleplayer.new("sfx/high")
sfx.play = pd.sound.sampleplayer.new("sfx/play")
sfx.click = pd.sound.sampleplayer.new("sfx/click")
sfx.tap = pd.sound.sampleplayer.new("sfx/tap")
sfx.jingle = pd.sound.sampleplayer.new("sfx/jingle")

menuBgm = pd.sound.fileplayer.new("bgm/Cosmos")

-- Song variables
currentSongList = songListSortedByArtist
currentSong = currentSongList[1]
currentDifficulty = currentSong.difficulties[1]
local mapList = currentSong.difficulties
songTable = {}
sortBy = ""
sortSongs = true
local songStarting = false
tutorialStarting = false
local songSelection = 1
local songSelectionRounded = songSelection
local mapSelection = -100
local mapSelectionRounded = 1
local oldMapSelection = mapSelectionRounded
local oldSongSelection = songSelectionRounded
local oldSongSelectionTime = 0
local playedPreview = false


-- Reset high scores variables
resetHiScores = false
local warningCurrentY = -45
warningTargetY = 5

-- Animation variables
local delta = 0
local sheenDuration = 600
local songBarCurrentY = 1000
local songBarTargetY = 800
local songBarCurrentRadius = 600
local songBarTargetRadius = 600
local selectBarCurrentY = -52
local selectBarTargetY = 0
local songDataCurrentX = math.min(-gfx.getTextSize(currentSong.name), -100)
local songDataTargetX = 0
local pointerCurrentY = screenHeight
local pointerTargetY = screenHeight-90
local fadeOut = 1
local playText = "Let's Go!"
local playTextWidth, playTextHeight = gfx.getTextSize(playText, fonts.odinRounded)
local playCurrentY = -playTextHeight
local playTargetY = playCurrentY
local controlsCurrentY = 250
local controlsTargetY = 200
local mapCurrentDist = 5
local mapTargetDist = 5
local mapSelectionOffset = -100


local function resetAnimationValues()
    delta = 0
    songBarCurrentY = 1000
    songBarTargetY = 800
    songBarCurrentRadius = 600
    songBarTargetRadius = 600
    selectBarCurrentY = -52
    selectBarTargetY = 0
    selecting = "song"
    mapSelectionOffset = -100
    songDataCurrentX = math.min(-gfx.getTextSize(currentSong.name), -100)
    songDataTargetX = 0
    pointerCurrentY = screenHeight
    pointerTargetY = screenHeight-90
    fadeOut = 1
    playCurrentY = -playTextHeight
    playTargetY = playCurrentY
    controlsCurrentY = 250
    controlsTargetY = 200
    mapCurrentDist = 5
    mapTargetDist = 5
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

    if delta == 1 then
        oldSongSelectionTime = 0
    end

    if not menuBgm:isPlaying() then
        menuBgm:play(0)
        menuBgm:setVolume(1)
    end

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

    -- check how long it's been since input
    if not leftHeld and not rightHeld and not upHeld and not downPressed and math.abs(crankChange) < 0.5 then
        ticksSinceInput += 1
    else
        ticksSinceInput = 0
    end

    -- make sure we're not in the reset high scores menu
    if not resetHiScores then
        -- check if we're selecting the song or the map
        if selecting == "song" then
            -- update the songSelection based on cranking and left/right presses
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
        end

        -- round the songSelection for things that need the exact songSelection
        songSelectionRounded = math.min(#songList, math.max(1, round(songSelection)))

        -- update the current song
        currentSong = currentSongList[songSelectionRounded]
        -- get the current list of maps (difficulties)
        mapList = currentSong.difficulties

        if selecting == "map" then
            -- update the mapSelection based on the cranking and left/right presses
            if leftPressed or leftHeldFor > 15 then
                mapSelection = round(mapSelection)-0.51
            end
            if rightPressed or rightHeldFor > 15 then
                mapSelection = round(mapSelection)+0.51
            end
            mapSelection += crankChange/45
        end 

        -- move the mapSelection to the nearest integer if not moving the crank or if past the edge of the list
        if math.abs(crankChange) < 0.5 or mapSelection > #mapList or mapSelection < 1 or selecting ~= "map" then
            mapSelection = closeDistance(mapSelection, math.min(#mapList, math.max(1, round(mapSelection))), 0.5)
        end
        -- round the mapSelection for things that need the exact mapSelection
        mapSelectionRounded = math.min(#mapList, math.max(1, round(mapSelection)))
        -- update what map (difficulty) is selected
        currentDifficulty = currentSong.difficulties[mapSelectionRounded]
        
        if (upPressed or aPressed) and not songStarting then
            if selecting == "play" then
                songStarting = true
                tutorialStarting = false
                sfx.play:play()
            elseif selecting == "map" then
                local songTablePath = "songs/"..currentSong.name.."/"..currentDifficulty..".json"
                -- check if the map exists, do nothing if not
                if pd.file.exists(songTablePath) then
                    selecting = "play"
                    sfx.high:play()
                end
            elseif selecting == "song" then
                selecting = "map"
                sfx.mid:play()
            end
        end

        if (downPressed or bPressed) and not songStarting then
            if selecting == "map" then
                selecting = "song"
                -- selectBarCurrentY = -52
                sfx.low:play()
            elseif selecting == "play" then
                selecting = "map"
                -- selectBarCurrentY = -52
                sfx.mid:play()
            end
        end

        if selecting == "play" then
            songBarTargetRadius = 400
            songBarTargetY = 700
            playTargetY = screenCenterY-playTextHeight/2
        elseif selecting == "map" then
            songBarTargetRadius = 500
            songBarTargetY = 725
            pointerTargetY = screenHeight-160
            playTargetY = -playTextHeight
            mapTargetDist = 10
        elseif selecting == "song" then
            songBarTargetRadius = 600
            songBarTargetY = 775
            pointerTargetY = screenHeight-115
            mapTargetDist = 5
        end
    
        
    else -- if we are in the reset menu
        if upHeld and aHeld then
            pd.datastore.write({}, "scores")
            scores = pd.datastore.read("scores")
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
        elseif sortBy == "name" then
            currentSongList = songListSortedByName
        else
            currentSongList = songListSortedByBpm
        end
        sortSongs = false
    end

    -- play a preview of the currently selected song
    local musicFile = ("songs/"..currentSong.name.."/"..currentSong.name)
    if songSelectionRounded == oldSongSelection then
        oldSongSelectionTime += 1
        if oldSongSelectionTime > 15 then
            if pd.file.exists(musicFile..".pda") then
                -- make the song fade in
                if not playedPreview then
                    music = pd.sound.fileplayer.new()
                    music:load(musicFile)
                    music:setVolume(0.01)
                    music:setVolume(1,1,1)
                    menuBgm:setVolume(0,0,1)
                    music:play()
                    music:setOffset(currentSong.preview)
                    playedPreview = true
                end
                -- make the song fade out
                if music:getVolume() == 0 then
                    music:stop()
                else
                    if music:getOffset() >= currentSong.preview+9 and music:getVolume() == 1 then
                        music:setVolume(0,0,1)
                        menuBgm:setVolume(1,1,1)
                    end
                end
            end
        end
    else
        oldSongSelection = songSelectionRounded
        oldSongSelectionTime = 0
        if music:isPlaying() then
            music:stop()
        end
        menuBgm:setVolume(1,1,1)
        playedPreview = false
        -- plays a click when moving to a new song
        sfx.click:play()
    end

    -- play a tap if rolling over maps
    if oldMapSelection ~= mapSelectionRounded then
        sfx.tap:play()
        oldMapSelection = mapSelectionRounded
    end
    
    if songStarting then
        -- get the map file path
        local songTablePath = "songs/"..currentSong.name.."/"..currentDifficulty..".json"
        -- fade out and then load map
        if fadeOut > 0 then
            fadeOut -= 0.1
        else
            local bpm = currentSong.bpm
            local beatOffset = currentSong.beatOffset
            if music:isPlaying() then
                music:stop()
            end
            menuBgm:stop()
            setUpSong(bpm, beatOffset, musicFile, songTablePath)
            resetAnimationValues()
            songStarting = false
            return "song"
        end
    end

    if tutorialStarting then
        -- get the map file path
        local songTablePath = "tutorial/Tutorial.json"
        -- check if the map exists, do nothing if not
        if not pd.file.exists(songTablePath) then
            songStarting = false
        else
            -- fade out and then load map
            if fadeOut > 0 then
                fadeOut -= 0.1
            else
                local tutorialData = json.decodeFile(pd.file.open("tutorial/songData.json"))
                local bpm = tutorialData.bpm
                local beatOffset = tutorialData.beatOffset
                if music:isPlaying() then
                    music:stop()
                end
                menuBgm:stop()
                local tutorialMusicFile = ("tutorial/Tutorial")
                setUpSong(bpm, beatOffset, tutorialMusicFile, songTablePath)
                resetAnimationValues()
                tutorialStarting = false
                return "song"
            end
        end
    end

    return "songSelect"
end



function drawSongSelect()
    -- draw background
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, screenWidth, screenHeight)

    -- draw background sheen
    local sheenX = sheenDuration-(delta%(sheenDuration+(sheenDuration-400)))
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5)
    gfx.setLineWidth(250)
    gfx.drawLine(sheenX, screenHeight+50, sheenX+30, -50)

    -- draw the song bar
    songBarCurrentY = closeDistance(songBarCurrentY, songBarTargetY, 0.3)
    songBarCurrentRadius = closeDistance(songBarCurrentRadius, songBarTargetRadius, 0.3)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(screenCenterX, songBarCurrentY, songBarCurrentRadius)
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(1/3, gfx.image.kDitherTypeDiagonalLine)
    gfx.fillCircleAtPoint(screenCenterX, songBarCurrentY, songBarCurrentRadius)
    gfx.setColor(gfx.kColorWhite)
    gfx.setLineWidth(5)
    gfx.drawCircleAtPoint(screenCenterX, songBarCurrentY, songBarCurrentRadius)
    -- songBarSprite:draw(0, songBarCurrentY-songBarCurrentRadius)


    -- draw the difficulty satellites
    mapCurrentDist = closeDistance(mapCurrentDist, mapTargetDist, 0.3)
    mapSelectionOffset = closeDistance(mapSelectionOffset, 0, 0.3)
    for i=#mapList,1,-1 do
        local mapPos = (i-mapSelection)*mapCurrentDist
        local mapScale = songBarCurrentRadius/500
        local mapX = screenCenterX + (songBarCurrentRadius+100) * math.cos(math.rad(mapPos-90+mapSelectionOffset))
        local mapY = songBarCurrentY/(songBarCurrentY/725) + (songBarCurrentRadius+100) * math.sin(math.rad(mapPos-90+mapSelectionOffset))

        -- draw difficuty availability
        local songTablePath = "songs/"..currentSong.name.."/"..mapList[i]..".json"
        -- check if the map exists, do nothing if not
        if not pd.file.exists(songTablePath) and selecting == "map" then
            local textWidth, textHeight = gfx.getTextSize("Unavailable", fonts.orbeatsSmall)
            local textX = mapX-textWidth/2
            local textY = mapY-textHeight/2-32*mapScale
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(textX-2, textY-2, textWidth+4, textHeight+4, 2)
            gfx.drawText("Unavailable", textX, textY, fonts.orbeatsSmall)
        end

        -- draw difficulty name
        local textWidth, textHeight = gfx.getTextSize(mapList[i], fonts.orbeatsSans)
        if textWidth > 100 then
            local textWidth, textHeight = gfx.getTextSize(mapList[i], fonts.orbeatsSmall)
            local textX = mapX-textWidth/2
            local textY = mapY-textHeight/2+32*mapScale
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(textX-2, textY-2, textWidth+4, textHeight+4, 2)
            gfx.drawText(mapList[i], textX, textY, fonts.orbeatsSmall)
        else
            local textX = mapX-textWidth/2
            local textY = mapY-textHeight/2+32*mapScale
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(textX-2, textY-2, textWidth+4, textHeight+4, 2)
            gfx.drawText(mapList[i], textX, textY, fonts.orbeatsSans)
        end
        
        -- draw difficulty icon
        local mapArtFilePath = "songs/"..currentSong.name.."/"..currentSong.difficulties[i]..".pdi"
        local missingArt = "sprites/missingMap"..(i%5)

        if pd.file.exists(mapArtFilePath) then
            -- getImage(mapArtFilePath):drawScaled(mapX-24*mapScale, mapY-24*mapScale, mapScale)
            getImage(mapArtFilePath):draw(mapX-24*mapScale, mapY-24*mapScale)
        else
            -- getImage(missingArt):drawScaled(mapX-24*mapScale, mapY-24*mapScale, mapScale)
            getImage(missingArt):draw(mapX-24*mapScale, mapY-24*mapScale)
        end
    end

    -- draw the song data
    songDataCurrentX = closeDistance(songDataCurrentX, songDataTargetX, 0.3)
    local dataBubbleWidth = 100
    local dataBubbleHeight = 85
    local dataBubbleY = 85
    -- draw main data bubble
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(songDataCurrentX, dataBubbleY, dataBubbleWidth, dataBubbleHeight, 5)
    local currentHiScore = 0
    local currentHiCombo = 0
    local currentBestRank = "-"
    if scores ~= nil then
        if scores[currentSong.name] ~= nil then
            if scores[currentSong.name][currentDifficulty] ~= nil then
                if scores[currentSong.name][currentDifficulty].score ~= nil then
                    currentHiScore = scores[currentSong.name][currentDifficulty].score
                end
                if scores[currentSong.name][currentDifficulty].rating ~= nil then
                    currentBestRank = scores[currentSong.name][currentDifficulty].rating
                end
                if scores[currentSong.name][currentDifficulty].combo ~= nil and scores[currentSong.name][currentDifficulty].fc ~= nil then
                    if scores[currentSong.name][currentDifficulty].fc then
                        currentHiCombo = -1
                    else
                        currentHiCombo = scores[currentSong.name][currentDifficulty].combo
                    end
                end
            end
        end
    end
    gfx.drawText("Best Score:", songDataCurrentX+5, dataBubbleY+5, fonts.orbeatsSmall)
    gfx.drawText(currentHiScore, songDataCurrentX+5, dataBubbleY+15, fonts.orbeatsSans)
    gfx.drawText("Best Combo:", songDataCurrentX+5, dataBubbleY+30, fonts.orbeatsSmall)
    if currentHiCombo < 0 then
        gfx.drawText("Full Combo", songDataCurrentX+5, dataBubbleY+40, fonts.orbeatsSans)
    else
        gfx.drawText(currentHiCombo, songDataCurrentX+5, dataBubbleY+40, fonts.orbeatsSans)
    end
    gfx.drawText("Best Rank:", songDataCurrentX+5, dataBubbleY+55, fonts.orbeatsSmall)
    gfx.drawText(currentBestRank, songDataCurrentX+5, dataBubbleY+65, fonts.orbeatsSans)
    -- draw the name/artist/bpm bubble
    local bpmText = currentSong.bpm.."BPM"
    local nameBubbleWidth = math.max(gfx.getTextSize(currentSong.name, fonts.orbeatsSans)+10, gfx.getTextSize(currentSong.artist, fonts.orbeatsSmall)+gfx.getTextSize(bpmText, fonts. orbeatsSmall)+20)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(songDataCurrentX, 30, nameBubbleWidth, 40, 5)
    gfx.drawText(bpmText, songDataCurrentX+gfx.getTextSize(currentSong.artist, fonts.orbeatsSmall)+13, 55, fonts.orbeatsSmall)
    gfx.drawText(currentSong.artist, songDataCurrentX+5, 55, fonts.orbeatsSmall)
    gfx.drawText(currentSong.name, songDataCurrentX+5, 35, fonts.orbeatsSans)
    
    

    -- draw the album art
    local missingArt = "sprites/missingArt"

    for i=songSelectionRounded+3,songSelectionRounded-3,-1 do
        if i <= #songList and i >= 1 then
            local albumArtFilePath = "songs/"..currentSongList[i].name.."/albumArt.pdi"

            local albumPos = -(songSelection-i)*8
            local albumScale = songBarCurrentRadius/600

            local albumX = screenCenterX + songBarCurrentRadius * math.cos(math.rad(albumPos-90)) - 32*albumScale
            local albumY = songBarCurrentY + songBarCurrentRadius * math.sin(math.rad(albumPos-90)) - 32*albumScale
            
            if pd.file.exists(albumArtFilePath) then
                -- getImage(albumArtFilePath):drawScaled(albumX, albumY, albumScale)
                getImage(albumArtFilePath):draw(albumX, albumY)
            else
                -- getImage(missingArt):drawScaled(albumX, albumY, albumScale)
                getImage(missingArt):draw(albumX, albumY)
            end
        end
    end

    -- draw the play text
    playCurrentY = closeDistance(playCurrentY, playTargetY, 0.3)
    if playCurrentY > -33 then
        gfx.drawText(playText, screenCenterX-playTextWidth/2, playCurrentY, fonts.odinRounded)
    end

    -- draw the pointer
    pointerCurrentY = closeDistance(pointerCurrentY, pointerTargetY, 0.3)
    pointerSprite:draw(screenCenterX-7, pointerCurrentY) 

    -- draw menu controls
    local controlsBubbleWidth = 50
    local controlsBubbleHeight = 26
    local drawControlsBubble = true
    if ticksSinceInput > 120 and selecting ~= "play" then
        controlsTargetY = 200
        if controlsTargetY == controlsCurrentY then
            drawControlsBubble = false
        end
    else
        controlsTargetY = 250
        drawControlsBubble = true
    end
    controlsCurrentY = closeDistance(controlsCurrentY, controlsTargetY, 0.3)
    if drawControlsBubble then
        -- draw the left controls bubble
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(0, controlsCurrentY, controlsBubbleWidth, controlsBubbleHeight, 3)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(0, controlsCurrentY, controlsBubbleWidth, controlsBubbleHeight, 3)
        gfx.drawText(char.left.."/"..char.ccw, 4, controlsCurrentY+4, fonts.orbeatsSans)
        -- draw the right controls bubble
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(350, controlsCurrentY, controlsBubbleWidth, controlsBubbleHeight, 3)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(350, controlsCurrentY, controlsBubbleWidth, 26, 3)
        gfx.drawText(char.right.."/"..char.cw, 355, controlsCurrentY+4, fonts.orbeatsSans)
    end
    
    -- draw the tutorial bubble
    local drawSelectBar = true
    if ticksSinceInput > 120 then
        selectBarTargetY = 0
    else
        if tutorialPlayed then
            selectBarTargetY = -52
            if selectBarCurrentY == selectBarTargetY then
                drawSelectBar = false
            end
        else
            selectBarTargetY = -26
            if delta % 15 <= 3 then
                drawSelectBar = false
            end
        end
    end
    selectBarCurrentY = closeDistance(selectBarCurrentY, selectBarTargetY, 0.3)

    local tutorialText = ("Tutorial & Options:"..char.menu)
    local tutorialTextWidth = gfx.getTextSize(tutorialText, fonts.orbeatsSans)
    if drawSelectBar then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(screenWidth-tutorialTextWidth-6, selectBarCurrentY, tutorialTextWidth+6, 50, 3)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(screenWidth-tutorialTextWidth-6, selectBarCurrentY, tutorialTextWidth+6, 50, 3)
        gfx.drawText(tutorialText, screenWidth-tutorialTextWidth-3, selectBarCurrentY+30, fonts.orbeatsSans)
    
        -- draw the up/down controls bar
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, selectBarCurrentY, screenWidth, 25)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawLine(0, selectBarCurrentY+25, screenWidth, selectBarCurrentY+25)
        local selectControlText = ""
        if selecting == "map" then
            selectControlText = "Confirm:"..char.up.."/"..char.A.." --- Back:"..char.down.."/"..char.B.." --- "
        elseif selecting == "play" then
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
    end


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

    -- draw fade out if fading out
    if fadeOut ~= 1 then
        gfx.setColor(gfx.kColorWhite)
        gfx.setDitherPattern(fadeOut)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
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