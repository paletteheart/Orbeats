
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
        songData.folder =  songFolders[i]
        print(songFolders[i])
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
        local loweredAName = string.lower(a.name)
        local loweredBName = string.lower(b.name)
        local loweredAArtist = string.lower(a.artist)
        local loweredBArtist = string.lower(b.artist)

        if loweredAName ~= loweredBName then
            return loweredAName < loweredBName
        else
            if loweredAArtist ~= loweredBArtist then
                return loweredAArtist < loweredBArtist
            else
                return a.bpm < b.bpm
            end
        end
    end)
    return sortedList
end
local function sortSongListByArtist()
    local sortedList = {}
    for i, v in ipairs(songList) do
        sortedList[i] = v  -- Copy original table's content to the new table
    end
    table.sort(sortedList, function(a, b)
        local loweredAName = string.lower(a.name)
        local loweredBName = string.lower(b.name)
        local loweredAArtist = string.lower(a.artist)
        local loweredBArtist = string.lower(b.artist)

        if loweredAArtist ~= loweredBArtist then
            return loweredAArtist < loweredBArtist
        else
            if loweredAName ~= loweredBName then
                return loweredAName < loweredBName
            else
                return a.bpm < b.bpm
            end
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
        local loweredAName = string.lower(a.name)
        local loweredBName = string.lower(b.name)
        local loweredAArtist = string.lower(a.artist)
        local loweredBArtist = string.lower(b.artist)

        if a.bpm ~= b.bpm then
            return a.bpm < b.bpm
        else
            if loweredAName ~= loweredBName then
                return loweredAName < loweredBName
            else
                return loweredAArtist < loweredBArtist
            end
        end
    end)
    return sortedList
end

local songListSortedByName <const> = sortSongListByName()
local songListSortedByArtist <const> = sortSongListByArtist()
local songListSortedByBpm <const> = sortSongListByBpm()

local songBarDither <const> = {0x95, 0x6A, 0xA9, 0x56, 0x59, 0xA6, 0x9A, 0x65}

-- Define variables
-- Misc variables
scores = pd.datastore.read("scores")

local leftHeldFor = 0 -- a measurement in ticks of how long left has been held
local rightHeldFor = 0 -- a measurement in ticks of how long right has been held
local selecting = "song"

pointerSprite = gfx.image.new("sprites/pointer")

-- Audio Variables
sfx.low = pd.sound.sampleplayer.new("sfx/low")
sfx.mid = pd.sound.sampleplayer.new("sfx/mid")
sfx.high = pd.sound.sampleplayer.new("sfx/high")
sfx.play = pd.sound.sampleplayer.new("sfx/play")
sfx.click = pd.sound.sampleplayer.new("sfx/click")
sfx.switch = pd.sound.sampleplayer.new("sfx/switch")
sfx.tap = pd.sound.sampleplayer.new("sfx/tap")
sfx.jingle = pd.sound.sampleplayer.new("sfx/jingle")

menuBgm = pd.sound.fileplayer.new("bgm/Cosmos")

-- Song variables
currentSongList = {}
currentSong = {}
currentDifficulty = ""
local mapList = {}
if #songList ~= 0 then
    currentSongList = songListSortedByArtist
    currentSong = currentSongList[1]
    currentDifficulty = currentSong.difficulties[1]
    mapList = currentSong.difficulties
end
songTable = {}
sortBy = ""
sortSongs = true
local songStarting = false
local toMenu = false
local songSelection = 1
local songSelectionRounded = songSelection
local mapSelection = -100
local mapSelectionRounded = 1
local oldMapSelection = mapSelectionRounded
local oldSongSelection = songSelectionRounded
local oldSongSelectionTime = 0
local playedPreview = false

-- Animation variables
local init = false

animationTime = 300

local sheenTimer = tmr.new(0, 600, 600)
sheenTimer.repeats = true

local tickerTimer = tmr.new(0, 0, 0)
tickerTimer.repeats = true
local tickerTextPlay = "Play:"..char.up.."/"..char.A.." --- Back:"..char.down.."/"..char.B.." --- "
local tickerTextConfirm = "Confirm:"..char.up.."/"..char.A.." --- Back:"..char.down.."/"..char.B.." --- "
local tickerTextBack = "Back:"..char.down.."/"..char.B.." --- Back:"..char.down.."/"..char.B.." --- "
local tickerText = tickerTextConfirm
local tickerTextWidth = gfx.getTextSize(tickerText, fonts.orbeatsSans)

local songBarY = 1000
local songBarYTimer = tmr.new(0, songBarY, songBarY)
local songBarRadius = 600
local songBarRadiusTimer = tmr.new(0, songBarRadius, songBarRadius)
local radiusPresets = {
    song = 600,
    map = 400,
    play = 200
}

local selectBarY = -52
local selectBarYTimer = tmr.new(0, selectBarY, selectBarY)
local drawInputPrompts = true


local songDataX
local songDataXTimer
if #songList ~= 0 then
    songDataX = math.min(-gfx.getTextSize(currentSong.name), -100)
    songDataXTimer = tmr.new(0, songDataX, songDataX)
end

local pointerY = screenHeight
local pointerYTimer = tmr.new(0, pointerY, pointerY)

local fadeWhite = 1
local fadeBlack = 1

local playText = "Let's Go!"
local playTextWidth, playTextHeight = gfx.getTextSize(playText, fonts.odinRounded)
local playY = -playTextHeight
local playYTimer = tmr.new(0, playY, playY)

local controlsY = 250
local controlsYTimer = tmr.new(0, controlsY, controlsY)

local mapDist = 5
local mapDistTimer = tmr.new(0, mapDist, mapDist)
local mapSelectionOffset = -100

local inputTimer = tmr.new(0)
local startHideAnimation = true

local missingText = "No songs yet!"

local function resetAnimTimers()
    songBarYTimer = replaceTimer(songBarYTimer, animationTime, songBarY, 775, ease.outBack)
    songBarRadiusTimer = replaceTimer(songBarRadiusTimer, animationTime, songBarRadius, radiusPresets.song, ease.outBack)
    selectBarYTimer = replaceTimer(selectBarYTimer, animationTime, selectBarY, 0, ease.outCubic)
    if #songList ~= 0 then
        songDataXTimer = replaceTimer(songDataXTimer, animationTime, songDataX, 0, ease.outCubic)
    end
    controlsYTimer = replaceTimer(controlsYTimer, animationTime, controlsY, 200, ease.outCubic)
    pointerYTimer = replaceTimer(pointerYTimer, animationTime, pointerY, screenHeight-115, ease.outBack)
    sheenTimer = replaceTimer(sheenTimer, 20000, 600, -200)
    sheenTimer.repeats = true
    tickerTimer = replaceTimer(tickerTimer, 7500, 0, tickerTextWidth)
    tickerTimer.repeats = true
end

local imageCache = {}
function getImage(path, mapNum)
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

function resetSongSelectAnim()
    init = false
    sheenTimer = replaceTimer(sheenTimer, 0, 600, 600)
    songBarY = 1000
    songBarYTimer = replaceTimer(songBarYTimer, 0, songBarY, songBarY)
    songBarRadius = 600
    songBarRadiusTimer = replaceTimer(songBarRadiusTimer, 0, songBarRadius, songBarRadius)
    selectBarY = -52
    selectBarYTimer = replaceTimer(selectBarYTimer, 0, selectBarY, selectBarY)
    selecting = "song"
    mapSelectionOffset = -100
    if #songList ~= 0 then
        songDataX = math.min(-gfx.getTextSize(currentSong.name), -100)
        songDataXTimer = replaceTimer(songDataXTimer, 0, songDataX, songDataX)
    end
    pointerY = screenHeight
    pointerYTimer = replaceTimer(pointerYTimer, 0, pointerY, pointerY)
    fadeWhite = 1
    fadeBlack = 1
    playY = -playTextHeight
    playYTimer = replaceTimer(playYTimer, 0, playY, playY)
    controlsY = 250
    controlsYTimer = replaceTimer(controlsYTimer, 0, controlsY, controlsY)
    mapDist = 5
    mapDistTimer = replaceTimer(mapDistTimer, 0, mapDist, mapDist)
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
    if #songList ~= 0 then
        if leftHeld or rightHeld or upHeld or downHeld or math.abs(crankChange) > 0.5 then
            inputTimer = replaceTimer(inputTimer, 4000, function()
                drawInputPrompts = true
                selectBarYTimer = replaceTimer(selectBarYTimer, animationTime, selectBarY, 0, ease.outCubic)
                controlsYTimer = replaceTimer(controlsYTimer, animationTime, controlsY, 200, ease.outCubic)
                startHideAnimation = true
            end)
    
            if selectBarYTimer.value == -56 then
                drawInputPrompts = false
            end
            if startHideAnimation then
                selectBarYTimer = replaceTimer(selectBarYTimer, animationTime, selectBarY, -52, ease.outCubic)
                controlsYTimer = replaceTimer(controlsYTimer, animationTime, controlsY, screenHeight+10, ease.outCubic)
                startHideAnimation = false
            end
        end
    end

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

    if #songList ~= 0 then
        -- update the current song
        currentSong = currentSongList[songSelectionRounded]
        -- get the current list of maps (difficulties)
        mapList = currentSong.difficulties
    end

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
    if #songList ~= 0 then
        currentDifficulty = currentSong.difficulties[mapSelectionRounded]
    end
    
    if #songList ~= 0 then
        if (upPressed or aPressed) and not songStarting then
            if selecting == "play" then
                songStarting = true
                sfx.play:play()
            elseif selecting == "map" then
                local songTablePath = "songs/"..currentSong.folder..currentDifficulty..".json"
                -- check if the map exists, do nothing if not
                if pd.file.exists(songTablePath) then
                    selecting = "play"
                    sfx.high:play()
                    songBarYTimer = replaceTimer(songBarYTimer, animationTime, songBarY, 700, ease.outBack)
                    songBarRadiusTimer = replaceTimer(songBarRadiusTimer, animationTime, songBarRadius, radiusPresets.play, ease.outBack)
                    playYTimer = replaceTimer(playYTimer, animationTime, playY, screenCenterY-playTextHeight/2, ease.outBack)
                    tickerText = tickerTextPlay
                    tickerTextWidth = gfx.getTextSize(tickerText, fonts.orbeatsSans)
                    tickerTimer = replaceTimer(tickerTimer, 7500, 0, tickerTextWidth)
                    tickerTimer.repeats = true
                end
            elseif selecting == "song" then
                selecting = "map"
                sfx.mid:play()
                songBarYTimer = replaceTimer(songBarYTimer, animationTime, songBarY, 725, ease.outBack)
                songBarRadiusTimer = replaceTimer(songBarRadiusTimer, animationTime, songBarRadius, radiusPresets.map, ease.outBack)
                pointerYTimer = replaceTimer(pointerYTimer, animationTime, pointerY, screenHeight-160, ease.outCubic)
                mapDistTimer = replaceTimer(mapDistTimer, animationTime, mapDist, 10, ease.outBack)
            end
        end
    end

    if (downPressed or bPressed) and not songStarting then
        if selecting == "map" then
            selecting = "song"
            sfx.low:play()
            songBarYTimer = replaceTimer(songBarYTimer, animationTime, songBarY, 775, ease.outBack)
            songBarRadiusTimer = replaceTimer(songBarRadiusTimer, animationTime, songBarRadius, radiusPresets.song, ease.outBack)
            pointerYTimer = replaceTimer(pointerYTimer, animationTime, pointerY, screenHeight-115, ease.outCubic)
            mapDistTimer = replaceTimer(mapDistTimer, animationTime, mapDist, 5, ease.outBack)
        elseif selecting == "play" then
            selecting = "map"
            songBarYTimer = replaceTimer(songBarYTimer, animationTime, songBarY, 725, ease.outBack)
            songBarRadiusTimer = replaceTimer(songBarRadiusTimer, animationTime, songBarRadius, radiusPresets.map, ease.outBack)
            playYTimer = replaceTimer(playYTimer, animationTime, playY, -playTextHeight, ease.outBack)
            sfx.mid:play()
            tickerText = tickerTextConfirm
            tickerTextWidth = gfx.getTextSize(tickerText, fonts.orbeatsSans)
            tickerTimer = replaceTimer(tickerTimer, 7500, 0, tickerTextWidth)
            tickerTimer.repeats = true
        elseif selecting == "song" then
            sfx.low:play()
            -- go back to the title
            toMenu = true
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
    if #songList ~= 0 then
        local musicFile = ("songs/"..currentSong.folder..currentSong.name)
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
    end

    -- play a tap if rolling over maps
    if oldMapSelection ~= mapSelectionRounded then
        sfx.tap:play()
        oldMapSelection = mapSelectionRounded
    end
    
    if songStarting then
        -- get the map file path
        local songTablePath = "songs/"..currentSong.folder..currentDifficulty..".json"
        -- fade out and then load map
        if fadeWhite > 0 then
            fadeWhite -= 0.1
        else
            local bpm = currentSong.bpm
            local bpmChanges = currentSong.bpmChange
            local beatOffset = currentSong.beatOffset
            local musicFile = ("songs/"..currentSong.folder..currentSong.name)
            if music:isPlaying() then
                music:stop()
            end
            menuBgm:stop()
            setUpSong(bpm, bpmChanges, beatOffset, musicFile, songTablePath)
            resetSongSelectAnim()
            songStarting = false
            return "song"
        end
    end

    

    if toMenu then
        -- go back to the title screen
        if fadeBlack > 0 then
            fadeBlack -= 0.1
        else
            resetSongSelectAnim()
            if music:isPlaying() then
                music:stop()
            end
            menuBgm:setVolume(1)
            toMenu = false
            return "menu"
        end
    end

    return "songSelect"
end



function drawSongSelect()

    -- draw background sheen
    local sheenX = sheenTimer.value
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5)
    gfx.setLineWidth(250)
    gfx.drawLine(sheenX, screenHeight+50, sheenX+30, -50)

    -- draw the song bar
    songBarY = songBarYTimer.value
    songBarRadius = songBarRadiusTimer.value
    if selecting == "song" or (selecting == "map" and songBarRadius > radiusPresets.map) then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(screenCenterX, songBarY, songBarRadius)
        gfx.setColor(gfx.kColorBlack)
        -- gfx.setDitherPattern(1/3, gfx.image.kDitherTypeDiagonalLine)
        gfx.setPattern(songBarDither)
        gfx.fillCircleAtPoint(screenCenterX, songBarY, songBarRadius)
        gfx.setColor(gfx.kColorWhite)
        gfx.setLineWidth(5)
        gfx.drawCircleAtPoint(screenCenterX, songBarY, songBarRadius)
        -- songBarSprite:draw(0, songBarY-songBarRadius)
    end

    -- check if there are any songs to display
    if #songList ~= 0 then
        -- draw the difficulty satellites
        if selecting == "map" or (selecting == "play" and songBarRadius > radiusPresets.play) or (selecting == "song" and songBarRadius < radiusPresets.song) then
            mapDist = mapDistTimer.value
            mapSelectionOffset = closeDistance(mapSelectionOffset, 0, 0.3)
            for i=mapSelectionRounded+3,mapSelectionRounded-3,-1 do
                if i <= #mapList and i >= 1 then
                    local mapPos = (i-mapSelection)*mapDist
                    local mapX = screenCenterX + (songBarRadius+200) * math.cos(math.rad(mapPos-90+mapSelectionOffset))
                    local mapY = songBarY/(songBarY/725) + (songBarRadius+200) * math.sin(math.rad(mapPos-90+mapSelectionOffset))
    
                    -- draw difficuty availability
                    local songTablePath = "songs/"..currentSong.folder..mapList[i]..".json"
                    -- check if the map exists, do nothing if not
                    if i == mapSelectionRounded then
                        if not pd.file.exists(songTablePath) then
                            local textWidth, textHeight = gfx.getTextSize("Unavailable", fonts.orbeatsSmall)
                            local textX = mapX-textWidth/2
                            local textY = mapY-textHeight/2+56
                            gfx.setColor(gfx.kColorWhite)
                            gfx.fillRoundRect(textX-2, textY-2, textWidth+4, textHeight+4, 2)
                            gfx.drawText("Unavailable", textX, textY, fonts.orbeatsSmall)
                        end
        
                        -- draw difficulty name
                        local textWidth, textHeight = gfx.getTextSize(mapList[i], fonts.orbeatsSans)
                        if textWidth > 100 then
                            local textWidth, textHeight = gfx.getTextSize(mapList[i], fonts.orbeatsSmall)
                            local textX = mapX-textWidth/2
                            local textY = mapY-textHeight/2+40
                            gfx.setColor(gfx.kColorWhite)
                            gfx.fillRoundRect(textX-2, textY-2, textWidth+4, textHeight+4, 2)
                            gfx.drawText(mapList[i], textX, textY, fonts.orbeatsSmall)
                        else
                            local textX = mapX-textWidth/2
                            local textY = mapY-textHeight/2+40
                            gfx.setColor(gfx.kColorWhite)
                            gfx.fillRoundRect(textX-2, textY-2, textWidth+4, textHeight+4, 2)
                            gfx.drawText(mapList[i], textX, textY, fonts.orbeatsSans)
                        end
                    end
                
                -- draw difficulty icon
                    local mapArtFilePath = "songs/"..currentSong.folder..currentSong.difficulties[i]..".pdi"
                    
                    getImage(mapArtFilePath, i):draw(mapX-24, mapY-24)
                end
            end
        end
    
        -- draw the song data
        songDataX = songDataXTimer.value
        local dataBubbleWidth = 100
        local dataBubbleHeight = 85
        local dataBubbleY = 85
        -- draw main data bubble
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(songDataX, dataBubbleY, dataBubbleWidth, dataBubbleHeight, 5)
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
        gfx.drawText("Best Score:", songDataX+5, dataBubbleY+5, fonts.orbeatsSmall)
        gfx.drawText(currentHiScore, songDataX+5, dataBubbleY+15, fonts.orbeatsSans)
        gfx.drawText("Best Combo:", songDataX+5, dataBubbleY+30, fonts.orbeatsSmall)
        if currentHiCombo < 0 then
            gfx.drawText("Full Combo", songDataX+5, dataBubbleY+40, fonts.orbeatsSans)
        else
            gfx.drawText(currentHiCombo, songDataX+5, dataBubbleY+40, fonts.orbeatsSans)
        end
        gfx.drawText("Best Rank:", songDataX+5, dataBubbleY+55, fonts.orbeatsSmall)
        gfx.drawText(currentBestRank, songDataX+5, dataBubbleY+65, fonts.orbeatsSans)
        -- draw the name/artist/bpm bubble
        local bpmText = currentSong.bpm.."BPM"
        local nameBubbleWidth = math.max(gfx.getTextSize(currentSong.name, fonts.orbeatsSans)+10, gfx.getTextSize(currentSong.artist, fonts.orbeatsSmall)+gfx.getTextSize(bpmText, fonts. orbeatsSmall)+20)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(songDataX, 30, nameBubbleWidth, 40, 5)
        gfx.drawText(bpmText, songDataX+gfx.getTextSize(currentSong.artist, fonts.orbeatsSmall)+13, 55, fonts.orbeatsSmall)
        gfx.drawText(currentSong.artist, songDataX+5, 55, fonts.orbeatsSmall)
        gfx.drawText(currentSong.name, songDataX+5, 35, fonts.orbeatsSans)
        
        
    
        -- draw the album art
        if selecting == "song" or (selecting == "map" and songBarRadius > radiusPresets.map) then
            for i=songSelectionRounded+3,songSelectionRounded-3,-1 do
                if i <= #songList and i >= 1 then
                    local albumArtFilePath = "songs/"..currentSongList[i].folder.."/albumArt.pdi"
        
                    local albumPos = -(songSelection-i)*8
                    local albumScale = songBarRadius/600
        
                    local albumX = screenCenterX + songBarRadius * math.cos(math.rad(albumPos-90)) - 32*albumScale
                    local albumY = songBarY + songBarRadius * math.sin(math.rad(albumPos-90)) - 32*albumScale
                    
                    getImage(albumArtFilePath):draw(albumX, albumY)
                end
            end
        end
    
        -- draw the play text
        playY = playYTimer.value
        if playY > -33 then
            if currentSong.confirmText ~= nil then
                local confirmText = currentSong.confirmText[mapList[mapSelectionRounded]]
                if confirmText ~= nil then
                    local confirmWidth = gfx.getTextSize(confirmText, fonts.odinRounded)
                    gfx.drawText(confirmText, screenCenterX-confirmWidth/2, playY, fonts.odinRounded)
                else
                    gfx.drawText(playText, screenCenterX-playTextWidth/2, playY, fonts.odinRounded)
                end
            else
                gfx.drawText(playText, screenCenterX-playTextWidth/2, playY, fonts.odinRounded)
            end
            
        end
    
        -- draw the pointer
        pointerY = pointerYTimer.value
        pointerSprite:draw(screenCenterX-7, pointerY) 
    
        -- draw menu controls
        local controlsBubbleWidth = 50
        local controlsBubbleHeight = 26
        controlsY = controlsYTimer.value
        if drawInputPrompts and selecting ~= "play" then
            -- draw the left controls bubble
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(0, controlsY, controlsBubbleWidth, controlsBubbleHeight, 3)
            gfx.setColor(gfx.kColorBlack)
            gfx.setLineWidth(2)
            gfx.drawRoundRect(0, controlsY, controlsBubbleWidth, controlsBubbleHeight, 3)
            gfx.drawText(char.left.."/"..char.ccw, 4, controlsY+4, fonts.orbeatsSans)
            -- draw the right controls bubble
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(350, controlsY, controlsBubbleWidth, controlsBubbleHeight, 3)
            gfx.setColor(gfx.kColorBlack)
            gfx.setLineWidth(2)
            gfx.drawRoundRect(350, controlsY, controlsBubbleWidth, 26, 3)
            gfx.drawText(char.right.."/"..char.cw, 355, controlsY+4, fonts.orbeatsSans)
        end
    end
    
    -- draw the sorting bubble and controls ticker
    selectBarY = selectBarYTimer.value

    local sortingText = ("Sorting:"..char.menu)
    local sortingTextWidth = gfx.getTextSize(sortingText, fonts.orbeatsSans)
    if drawInputPrompts then
        -- draw the sorting button prompt
        if #songList ~= 0 then
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(screenWidth-sortingTextWidth-6, selectBarY, sortingTextWidth+6, 50, 3)
            gfx.setColor(gfx.kColorBlack)
            gfx.setLineWidth(2)
            gfx.drawRoundRect(screenWidth-sortingTextWidth-6, selectBarY, sortingTextWidth+6, 50, 3)
            gfx.drawText(sortingText, screenWidth-sortingTextWidth-3, selectBarY+30, fonts.orbeatsSans)
        end
    
        -- draw the up/down controls bar
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, selectBarY, screenWidth, 25)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawLine(0, selectBarY+25, screenWidth, selectBarY+25)
        local tickerX1 = tickerTimer.value
        local tickerX2 = tickerTimer.value-tickerTextWidth
        local tickerX3 = tickerTimer.value+tickerTextWidth
        gfx.drawText(tickerText, tickerX1, selectBarY+4, fonts.orbeatsSans)
        gfx.drawText(tickerText, tickerX2, selectBarY+4, fonts.orbeatsSans)
        gfx.drawText(tickerText, tickerX3, selectBarY+4, fonts.orbeatsSans)
    end

    if #songList == 0 then
        drawTextCentered(missingText, screenCenterX, screenCenterY, fonts.odinRounded)
    end

    -- draw fade out if fading out
    if fadeWhite ~= 1 then
        gfx.setColor(gfx.kColorWhite)
        gfx.setDitherPattern(fadeWhite)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    end
    if fadeBlack ~= 1 then
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(fadeBlack)
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

function round(number)
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

function replaceTimer(timer, ...)
    timer:remove()
    return tmr.new(...)
end