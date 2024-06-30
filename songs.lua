
import "game"

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics
local tmr <const> = pd.timer
local ease <const> = pd.easingFunctions

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
local toTitle = false
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
warningCurrentY = -45
warningYTimer = tmr.new(0, warningCurrentY, warningCurrentY)

-- Animation variables
local init = false

animationTime = 300

local sheenTimer = tmr.new(0, 600, 600)
sheenTimer.repeats = true

local tickerTimer = tmr.new(0, 0, 0)
tickerTimer.repeats = true
local tickerTextPlay = "Play:"..char.up.."/"..char.A.." --- Back:"..char.down.."/"..char.B.." --- "
local tickerTextConfirm = "Confirm:"..char.up.."/"..char.A.." --- Back:"..char.down.."/"..char.A.." --- "
local tickerText = tickerTextConfirm
local tickerTextWidth = gfx.getTextSize(tickerText, fonts.orbeatsSans)

local songBarCurrentY = 1000
local songBarYTimer = tmr.new(0, songBarCurrentY, songBarCurrentY)
local songBarCurrentRadius = 600
local songBarRadiusTimer = tmr.new(0, songBarCurrentRadius, songBarCurrentRadius)

local selectBarCurrentY = -52
local selectBarYTimer = tmr.new(0, selectBarCurrentY, selectBarCurrentY)
local drawInputPrompts = true

local songDataCurrentX = math.min(-gfx.getTextSize(currentSong.name), -100)
local songDataXTimer = tmr.new(0, songDataCurrentX, songDataCurrentX)

local pointerCurrentY = screenHeight
local pointerYTimer = tmr.new(0, pointerCurrentY, pointerCurrentY)

local fadeOut = 1

local playText = "Let's Go!"
local playTextWidth, playTextHeight = gfx.getTextSize(playText, fonts.odinRounded)
local playCurrentY = -playTextHeight
local playYTimer = tmr.new(0, playCurrentY, playCurrentY)

local controlsCurrentY = 250
local controlsYTimer = tmr.new(0, controlsCurrentY, controlsCurrentY)

local mapCurrentDist = 5
local mapDistTimer = tmr.new(0, mapCurrentDist, mapCurrentDist)
local mapSelectionOffset = -100

local inputTimer = tmr.new(0)
local startHideAnimation = true


local function resetAnimValues()
    init = false
    songBarCurrentY = 1000
    songBarYTimer = replaceTimer(songBarYTimer, 0, songBarCurrentY, songBarCurrentY)
    songBarCurrentRadius = 600
    songBarRadiusTimer = replaceTimer(songBarRadiusTimer, 0, songBarCurrentRadius, songBarCurrentRadius)
    selectBarCurrentY = -52
    selectBarYTimer = replaceTimer(selectBarYTimer, 0, selectBarCurrentY, selectBarCurrentY)
    selecting = "song"
    mapSelectionOffset = -100
    songDataCurrentX = math.min(-gfx.getTextSize(currentSong.name), -100)
    songDataXTimer = replaceTimer(songDataXTimer, 0, songDataCurrentX, songDataCurrentX)
    pointerCurrentY = screenHeight
    pointerYTimer = replaceTimer(pointerYTimer, 0, pointerCurrentY, pointerCurrentY)
    fadeOut = 1
    playCurrentY = -playTextHeight
    playYTimer = replaceTimer(playYTimer, 0, playCurrentY, playCurrentY)
    controlsCurrentY = 250
    controlsYTimer = replaceTimer(controlsYTimer, 0, controlsCurrentY, controlsCurrentY)
    mapCurrentDist = 5
    mapDistTimer = replaceTimer(mapDistTimer, 0, mapCurrentDist, mapCurrentDist)
end

local function resetAnimTimers()
    songBarYTimer = replaceTimer(songBarYTimer, animationTime, songBarCurrentY, 775, ease.outCubic)
    songBarRadiusTimer = replaceTimer(songBarRadiusTimer, animationTime, songBarCurrentRadius, 600, ease.outCubic)
    selectBarYTimer = replaceTimer(selectBarYTimer, animationTime, selectBarCurrentY, 0, ease.outCubic)
    songDataXTimer = replaceTimer(songDataXTimer, animationTime, songDataCurrentX, 0, ease.outCubic)
    controlsYTimer = replaceTimer(controlsYTimer, animationTime, controlsCurrentY, 200, ease.outCubic)
    pointerYTimer = replaceTimer(pointerYTimer, animationTime, pointerCurrentY, screenHeight-115, ease.outCubic)
    sheenTimer = replaceTimer(sheenTimer, 20000, 600, -200)
    sheenTimer.repeats = true
    tickerTimer = replaceTimer(tickerTimer, 7500, 0, tickerTextWidth)
    tickerTimer.repeats = true
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
local function getImage(path, mapNum)
    if imageCache[path] == nil then
        if pd.file.exists(path) then
            imageCache[path] = gfx.image.new(path)
        else
            -- check if we're caching a difficulty map icon
            if mapNum == nil then
                imageCache[path] = gfx.image.new("sprites/missingArt")
            else
                -- if true, give it the correct icons
                imageCache[path] = gfx.image.new("sprites/missingMap"..(mapNum%5))
            end
        end
    end
    return imageCache[path]
end

function updateSongSelect()

    if not init then
        oldSongSelectionTime = 0
        resetAnimTimers()
        init = true
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

    -- set up timers for input prompts when recieving inputs
    if leftHeld or rightHeld or upHeld or downHeld or math.abs(crankChange) > 0.5 then
        inputTimer = replaceTimer(inputTimer, 4000, function()
            drawInputPrompts = true
            selectBarYTimer = replaceTimer(selectBarYTimer, animationTime, selectBarCurrentY, 0, ease.outCubic)
            controlsYTimer = replaceTimer(controlsYTimer, animationTime, controlsCurrentY, 200, ease.outCubic)
            startHideAnimation = true
        end)

        if selectBarYTimer.value == -56 then
            drawInputPrompts = false
        end
        if startHideAnimation then
            if tutorialPlayed then
                selectBarYTimer = replaceTimer(selectBarYTimer, animationTime, selectBarCurrentY, -52, ease.outCubic)
            else
                selectBarYTimer = replaceTimer(selectBarYTimer, animationTime, selectBarCurrentY, -26, ease.outCubic)
            end
            controlsYTimer = replaceTimer(controlsYTimer, animationTime, controlsCurrentY, screenHeight+10, ease.outCubic)
            startHideAnimation = false
        end
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
            if math.abs(crankChange) < 0.1 or songSelection > #songList or songSelection < 1 then
                songSelection = closeDistance(songSelection, math.min(#songList, math.max(1, round(songSelection))), 0.3)
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
            mapSelection = closeDistance(mapSelection, math.min(#mapList, math.max(1, round(mapSelection))), 0.3)
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
                    songBarYTimer = replaceTimer(songBarYTimer, animationTime, songBarCurrentY, 700, ease.outCubic)
                    songBarRadiusTimer = replaceTimer(songBarRadiusTimer, animationTime, songBarCurrentRadius, 400, ease.outCubic)
                    playYTimer = replaceTimer(playYTimer, animationTime, playCurrentY, screenCenterY-playTextHeight/2, ease.outCubic)
                    tickerText = tickerTextPlay
                    tickerTextWidth = gfx.getTextSize(tickerText, fonts.orbeatsSans)
                    tickerTimer = replaceTimer(tickerTimer, 7500, 0, tickerTextWidth)
                    tickerTimer.repeats = true
                end
            elseif selecting == "song" then
                selecting = "map"
                sfx.mid:play()
                songBarYTimer = replaceTimer(songBarYTimer, animationTime, songBarCurrentY, 725, ease.outCubic)
                songBarRadiusTimer = replaceTimer(songBarRadiusTimer, animationTime, songBarCurrentRadius, 500, ease.outCubic)
                pointerYTimer = replaceTimer(pointerYTimer, animationTime, pointerCurrentY, screenHeight-160, ease.outCubic)
                mapDistTimer = replaceTimer(mapDistTimer, animationTime, mapCurrentDist, 10, ease.outCubic)
            end
        end

        if (downPressed or bPressed) and not songStarting then
            if selecting == "map" then
                selecting = "song"
                sfx.low:play()
                songBarYTimer = replaceTimer(songBarYTimer, animationTime, songBarCurrentY, 775, ease.outCubic)
                songBarRadiusTimer = replaceTimer(songBarRadiusTimer, animationTime, songBarCurrentRadius, 600, ease.outCubic)
                pointerYTimer = replaceTimer(pointerYTimer, animationTime, pointerCurrentY, screenHeight-115, ease.outCubic)
                mapDistTimer = replaceTimer(mapDistTimer, animationTime, mapCurrentDist, 5, ease.outCubic)
            elseif selecting == "play" then
                selecting = "map"
                songBarYTimer = replaceTimer(songBarYTimer, animationTime, songBarCurrentY, 725, ease.outCubic)
                songBarRadiusTimer = replaceTimer(songBarRadiusTimer, animationTime, songBarCurrentRadius, 500, ease.outCubic)
                playYTimer = replaceTimer(playYTimer, animationTime, playCurrentY, -playTextHeight, ease.outCubic)
                sfx.mid:play()
                tickerText = tickerTextConfirm
                tickerTextWidth = gfx.getTextSize(tickerText, fonts.orbeatsSans)
                tickerTimer = replaceTimer(tickerTimer, 7500, 0, tickerTextWidth)
                tickerTimer.repeats = true
            elseif selecting == "song" then
                sfx.low:play()
                -- go back to the title
                toTitle = true
            end
        end
    
        
    else -- if we are in the reset menu
        if upHeld and aHeld then
            pd.datastore.write({}, "scores")
            scores = pd.datastore.read("scores")
            warningYTimer = replaceTimer(warningYTimer, animationTime, warningCurrentY, -45, ease.outCubic)
            resetHiScores = false
        elseif downPressed or bPressed then
            warningYTimer = replaceTimer(warningYTimer, animationTime, warningCurrentY, -45, ease.outCubic)
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
            local bpmChanges = currentSong.bpmChange
            local beatOffset = currentSong.beatOffset
            if music:isPlaying() then
                music:stop()
            end
            menuBgm:stop()
            setUpSong(bpm, bpmChanges, beatOffset, musicFile, songTablePath)
            resetAnimValues()
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
                local bpmChanges = tutorialData.bpmChange
                local beatOffset = tutorialData.beatOffset
                if music:isPlaying() then
                    music:stop()
                end
                menuBgm:stop()
                local tutorialMusicFile = ("tutorial/Tutorial")
                setUpSong(bpm, bpmChanges, beatOffset, tutorialMusicFile, songTablePath)
                resetAnimValues()
                tutorialStarting = false
                return "song"
            end
        end
    end

    if toTitle then
        -- go back to the title screen
        if fadeOut > 0 then
            fadeOut -= 0.1
        else
            resetAnimValues()
            if music:isPlaying() then
                music:stop()
            end
            menuBgm:stop()
            toTitle = false
            return "title"
        end
    end

    return "songSelect"
end



function drawSongSelect()
    -- draw background
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, screenWidth, screenHeight)

    -- draw background sheen
    local sheenX = sheenTimer.value
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5)
    gfx.setLineWidth(250)
    gfx.drawLine(sheenX, screenHeight+50, sheenX+30, -50)

    -- draw the song bar
    songBarCurrentY = songBarYTimer.value
    songBarCurrentRadius = songBarRadiusTimer.value
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(screenCenterX, songBarCurrentY, songBarCurrentRadius)
    gfx.setColor(gfx.kColorBlack)
    -- gfx.setDitherPattern(1/3, gfx.image.kDitherTypeDiagonalLine)
    gfx.setPattern({0x95, 0x6A, 0xA9, 0x56, 0x59, 0xA6, 0x9A, 0x65})
    gfx.fillCircleAtPoint(screenCenterX, songBarCurrentY, songBarCurrentRadius)
    gfx.setColor(gfx.kColorWhite)
    gfx.setLineWidth(5)
    gfx.drawCircleAtPoint(screenCenterX, songBarCurrentY, songBarCurrentRadius)
    -- songBarSprite:draw(0, songBarCurrentY-songBarCurrentRadius)


    -- draw the difficulty satellites
    mapCurrentDist = mapDistTimer.value
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
        
        getImage(mapArtFilePath, i):draw(mapX-24*mapScale, mapY-24*mapScale)
    end

    -- draw the song data
    songDataCurrentX = songDataXTimer.value
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
    

    for i=songSelectionRounded+3,songSelectionRounded-3,-1 do
        if i <= #songList and i >= 1 then
            local albumArtFilePath = "songs/"..currentSongList[i].name.."/albumArt.pdi"

            local albumPos = -(songSelection-i)*8
            local albumScale = songBarCurrentRadius/600

            local albumX = screenCenterX + songBarCurrentRadius * math.cos(math.rad(albumPos-90)) - 32*albumScale
            local albumY = songBarCurrentY + songBarCurrentRadius * math.sin(math.rad(albumPos-90)) - 32*albumScale
            
            getImage(albumArtFilePath):draw(albumX, albumY)
        end
    end

    -- draw the play text
    playCurrentY = playYTimer.value
    if playCurrentY > -33 then
        gfx.drawText(playText, screenCenterX-playTextWidth/2, playCurrentY, fonts.odinRounded)
    end

    -- draw the pointer
    pointerCurrentY = pointerYTimer.value
    pointerSprite:draw(screenCenterX-7, pointerCurrentY) 

    -- draw menu controls
    local controlsBubbleWidth = 50
    local controlsBubbleHeight = 26
    controlsCurrentY = controlsYTimer.value
    if drawInputPrompts and selecting ~= "play" then
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
    selectBarCurrentY = selectBarYTimer.value

    local tutorialText = ("Tutorial & Options:"..char.menu)
    local tutorialTextWidth = gfx.getTextSize(tutorialText, fonts.orbeatsSans)
    if drawInputPrompts then
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
        local tickerX1 = tickerTimer.value
        local tickerX2 = tickerTimer.value-tickerTextWidth
        local tickerX3 = tickerTimer.value+tickerTextWidth
        gfx.drawText(tickerText, tickerX1, selectBarCurrentY+4, fonts.orbeatsSans)
        gfx.drawText(tickerText, tickerX2, selectBarCurrentY+4, fonts.orbeatsSans)
        gfx.drawText(tickerText, tickerX3, selectBarCurrentY+4, fonts.orbeatsSans)
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
        if warningCurrentY ~= warningYTimer.value then
            warningCurrentY = warningYTimer.value
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

function replaceTimer(timer, ...)
    timer:remove()
    return tmr.new(...)
end