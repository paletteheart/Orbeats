
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

local songBarRadius <const> = 600
local songBarDither <const> = {0x95, 0x6A, 0xA9, 0x56, 0x59, 0xA6, 0x9A, 0x65}
-- Cache song bar
local function cacheSongBar()
    local barHeight = 125
    local lineThickness = 5

    barHeight = barHeight+lineThickness
    local img = gfx.image.new(screenWidth, barHeight)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleInRect(screenCenterX-songBarRadius, lineThickness, songBarRadius*2, songBarRadius*2)
        gfx.setColor(gfx.kColorBlack)
        gfx.setPattern(songBarDither)
        gfx.fillCircleInRect(screenCenterX-songBarRadius, lineThickness, songBarRadius*2, songBarRadius*2)
        gfx.setColor(gfx.kColorWhite)
        gfx.setLineWidth(lineThickness)
        gfx.drawCircleInRect(screenCenterX-songBarRadius, lineThickness, songBarRadius*2, songBarRadius*2)
    gfx.popContext()

    return img, barHeight
end
local songBarImg <const>, songBarH <const> = cacheSongBar()

local albumArtSize <const> = 64
local albumArtCenter <const> = albumArtSize/2
local difficultyArtSize <const> = 48
local difficultyArtCenter <const> = difficultyArtSize/2

local tickerTextPlay <const> = gfx.imageWithText("Play:"..char.up.."/"..char.A.." --- Back:"..char.down.."/"..char.B.." --- ", 400, 400, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSans)
local tickerTextConfirm <const> = gfx.imageWithText("Confirm:"..char.up.."/"..char.A.." --- Back:"..char.down.."/"..char.B.." --- ", 400, 400, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSans)
local tickerTextBack <const> = gfx.imageWithText("Back:"..char.down.."/"..char.B.." --- Back:"..char.down.."/"..char.B.." --- ", 400, 400, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSans)

local leftControls <const> = gfx.imageWithText(char.left.."/"..char.ccw, 400, 400, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSans)
local rightControls <const> = gfx.imageWithText(char.right.."/"..char.cw, 400, 400, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSans)
local sortingControls <const> = gfx.imageWithText("Sorting:"..char.menu, 400, 400, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSans)

local songDataText <const> = {
    score = gfx.imageWithText("Best Score:", 100, 100, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSmall),
    combo = gfx.imageWithText("Best Combo:", 100, 100, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSmall),
    fc = gfx.imageWithText("Full Combo", 100, 100, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSans),
    rank = gfx.imageWithText("Best Rank:", 100, 100, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSmall)
}

local playText <const> = "Let's Go!"
local playTextWidth <const>, playTextHeight <const> = gfx.getTextSize(playText, fontFamilies.odinRounded)
local unavailText <const> = "Unavailable."
local unavailTextWidth <const>, unavailTextHeight <const> = gfx.getTextSize(unavailText, fontFamilies.odinRounded)
local missingText <const> = "No songs yet!"

local mapDistPresets <const> = {
    close = 5,
    far = 10
}
local menuYPresets <const> = {
    songs = 0,
    maps = screenCenterY+songBarH,
    play = screenHeight+songBarH*2,
    reveal = screenCenterY+songBarH
}
local pointerYPresets <const> = {
    songs = screenCenterY,
    maps = 80,
    play = 80,
    reveal = screenHeight
}
local controlsYPresets <const> = {
    show = 215,
    hide = screenHeight+10
}
local selectYPresets <const> = {
    show = 0,
    hide = -52
}

local hasSongs <const> = #songList ~= 0

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
sortBy = settings.songSorting
currentSongList = {}
currentSong = {}
currentDifficulty = ""
local mapList = {}
if hasSongs then
    if sortBy == "artist" then
        currentSongList = songListSortedByArtist
    elseif sortBy == "name" then
        currentSongList = songListSortedByName
    else
        currentSongList = songListSortedByBpm
    end
    currentSong = currentSongList[1]
    currentDifficulty = currentSong.difficulties[1]
    mapList = currentSong.difficulties
end
songTable = {}
sortSongs = true
local songStarting = false
local toMenu = false
local songSelection = 1
local songSelectionRounded = songSelection
local mapSelection = 1
local mapSelectionRounded = 1
local oldMapSelection = mapSelectionRounded
local oldSongSelection = songSelectionRounded
local oldSongSelectionTime = 0
local playedPreview = false
local songTablePath


-- Animation variables
local init = false

animationTime = 300

local tickerText = tickerTextConfirm
local tickerTextWidth = tickerText:getSize()

local menuY = menuYPresets.reveal

local drawInputPrompts = true

local songDataX = -200

local pointerY = pointerYPresets.reveal
local targetPointerY = pointerYPresets.songs

local fadeWhite = 1
local fadeBlack = 1

local playY = -playTextHeight

local mapDist = mapDistPresets.close
local mapSelectionOffset = -1000

local startHideAnimation = true

-- Timers

local menuYTimer = tmr.new(0, menuYPresets.reveal, menuYPresets.reveal)
local sheenTimer = tmr.new(0, 600, 600)
sheenTimer.repeats = true
local tickerTimer = tmr.new(0)
tickerTimer.repeats = true
local inputTimer = tmr.new(0)
local controlsTimer = tmr.new(0)

-- Local functions

local function resetAnimTimers()
    menuYTimer = replaceTimer(menuYTimer, animationTime, menuYPresets.reveal, menuYPresets.songs, ease.outBack)
    controlsTimer = replaceTimer(controlsTimer, animationTime, 0, 1, ease.outCubic)
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

-- Global functions

function resetSongSelectAnim()
    init = false
    sheenTimer = replaceTimer(sheenTimer, 0, 600, 600)
    menuYTimer = replaceTimer(menuYTimer, 0, menuYPresets.reveal, menuYPresets.reveal)
    controlsTimer = replaceTimer(controlsTimer, 0, 0, 0)
    selecting = "song"
    mapSelectionOffset = -1000
    songDataX = -200
    pointerY = pointerYPresets.reveal
    targetPointerY = pointerYPresets.songs
    fadeWhite = 1
    fadeBlack = 1
    playY = -playTextHeight
    mapDist = mapDistPresets.close
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
    if hasSongs then
        -- only draw controls if they're not fully hidden
        if controlsTimer.value == 0 and not startHideAnimation then
            drawInputPrompts = false
        end
        -- update animations if inputs given
        if leftHeld or rightHeld or upHeld or downHeld or aHeld or bHeld or math.abs(crankChange) > 0.5 then
            inputTimer = replaceTimer(inputTimer, 4000, function()
                drawInputPrompts = true
                controlsTimer = replaceTimer(controlsTimer, animationTime, controlsTimer.value, 1.0, ease.outCubic)
                startHideAnimation = true
            end)
    
            if startHideAnimation then
                controlsTimer = replaceTimer(controlsTimer, animationTime, controlsTimer.value, 0.0, ease.outCubic)
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

    -- update the current song
    if hasSongs then
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
    if hasSongs then
        currentDifficulty = currentSong.difficulties[mapSelectionRounded]
    end
    
    local pathTable = {"songs/", currentSong.folder, currentDifficulty, ".json"}
    songTablePath = table.concat(pathTable)
    if hasSongs then
        if (upPressed or aPressed) and not songStarting then
            if selecting == "play" then
                -- check if the map exists, do nothing if not
                if pd.file.exists(songTablePath) then
                    songStarting = true
                    sfx.play:play()
                end
            elseif selecting == "map" then
                songTablePath = "songs/"..currentSong.folder..currentDifficulty..".json"
                selecting = "play"
                sfx.high:play()
                menuYTimer = replaceTimer(menuYTimer, animationTime, menuY, menuYPresets.play, ease.outBack)
                tickerText = tickerTextPlay
                local tth
                tickerTextWidth, tth = tickerText:getSize()
                tickerTimer = replaceTimer(tickerTimer, 7500, 0, tickerTextWidth)
                tickerTimer.repeats = true
                targetPointerY = pointerYPresets.play
            elseif selecting == "song" then
                selecting = "map"
                sfx.mid:play()
                menuYTimer = replaceTimer(menuYTimer, animationTime, menuY, menuYPresets.maps, ease.outBack)
                targetPointerY = 80
            end
        end
    end

    if (downPressed or bPressed) and not songStarting then
        if selecting == "map" then
            selecting = "song"
            sfx.low:play()
            menuYTimer = replaceTimer(menuYTimer, animationTime, menuY, menuYPresets.songs, ease.outBack)
            targetPointerY = pointerYPresets.songs
        elseif selecting == "play" then
            selecting = "map"
            menuYTimer = replaceTimer(menuYTimer, animationTime, menuY, menuYPresets.maps, ease.outBack)
            sfx.mid:play()
            tickerText = tickerTextConfirm
            local tth
            tickerTextWidth, tth = tickerText:getSize()
            tickerTimer = replaceTimer(tickerTimer, 7500, 0, tickerTextWidth)
            tickerTimer.repeats = true
            targetPointerY = pointerYPresets.maps
        elseif selecting == "song" then
            sfx.low:play()
            -- go back to the title
            toMenu = true
        end
    end

    -- play a preview of the currently selected song
    if hasSongs then
        local fileTable = {"songs/", currentSong.folder, currentSong.name}
        local musicFile = table.concat(fileTable)
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
        -- fade out and then load map 
        if fadeWhite > 0 then
            fadeWhite -= 0.1
        else
            local bpm = currentSong.bpm
            local bpmChanges = currentSong.bpmChanges
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
    -- update the menu Y
    menuY = menuYTimer.value

    -- draw background sheen
    local sheenX = sheenTimer.value
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5)
    gfx.setLineWidth(250)
    gfx.drawLine(sheenX, screenHeight+50, sheenX+30, -50)

    -- draw the song bar
    local songBarY = menuY + screenHeight - songBarH*0.5
    if selecting == "song" or (selecting == "map" and menuY < menuYPresets.maps) then
        songBarImg:draw(0, songBarY)
    end

    -- check if there are any songs to display
    local mapExists = false
    if hasSongs then
        local pathTable = {"songs/", currentSong.folder, mapList[mapSelectionRounded], ".json"}
        local songPath = table.concat(pathTable)
        mapExists = pd.file.exists(songPath)

        -- draw the difficulty satellites
        if selecting == "map" or (selecting == "play" and menuY < menuYPresets.play) or (selecting == "song" and menuY > menuYPresets.songs) then
            
            -- calculate satellite distance
            local mapDistDiff = mapDistPresets.far - mapDistPresets.close
            local menuDist = 1-(math.abs(menuY - menuYPresets.maps)/menuYPresets.maps) -- normalized
            mapDist = mapDistPresets.close + menuDist*mapDistDiff

            mapSelectionOffset = closeDistance(mapSelectionOffset, 0, 0.3)
            for i=mapSelectionRounded+3,mapSelectionRounded-3,-1 do
                if i <= #mapList and i >= 1 then
                    local mapPos = (i-mapSelection)*mapDist
                    local mapX = screenCenterX + (songBarRadius+200) * math.cos(math.rad(mapPos-90))
                    local mapY = mapSelectionOffset + menuY - screenCenterY + songBarRadius + songBarRadius * math.sin(math.rad(mapPos-90))
                    -- round the position to the nearest even number so dither doesn't kill anyone
                    mapX = math.floor(mapX/2)*2
                    mapY = math.floor(mapY/2)*2
    
                    -- draw difficuty availability
                    -- check if the map exists, do nothing if not
                    if i == mapSelectionRounded then
                        -- if not pd.file.exists(songPath) then
                        --     local textWidth, textHeight = gfx.getTextSize("Unavailable", fontFamilies.orbeatsSmall)
                        --     local textX = mapX-textWidth/2
                        --     local textY = mapY-textHeight/2+56
                        --     gfx.setColor(gfx.kColorWhite)
                        --     gfx.fillRoundRect(textX-2, textY-2, textWidth+4, textHeight+4, 2)
                        --     gfx.drawText("Unavailable", textX, textY, fontFamilies.orbeatsSmall)
                        -- end
        
                        -- draw difficulty name
                        local textWidth, textHeight = gfx.getTextSize(mapList[i], fontFamilies.orbeatsSans)
                        if textWidth > 100 then
                            local textWidth, textHeight = gfx.getTextSize(mapList[i], fontFamilies.orbeatsSmall)
                            local textX = mapX-textWidth/2
                            local textY = mapY-textHeight/2+40
                            gfx.setColor(gfx.kColorWhite)
                            gfx.fillRoundRect(textX-2, textY-2, textWidth+4, textHeight+4, 2)
                            gfx.drawText(mapList[i], textX, textY, fontFamilies.orbeatsSmall)
                        else
                            local textX = mapX-textWidth/2
                            local textY = mapY-textHeight/2+40
                            gfx.setColor(gfx.kColorWhite)
                            gfx.fillRoundRect(textX-2, textY-2, textWidth+4, textHeight+4, 2)
                            gfx.drawText(mapList[i], textX, textY, fontFamilies.orbeatsSans)
                        end
                    end
                
                    -- draw difficulty icon
                    local filePath = {"songs/", currentSong.folder, currentSong.difficulties[i], ".pdi"}
                    local mapArtFilePath = table.concat(filePath)
                    
                    getImage(mapArtFilePath, i):draw(mapX-24, mapY-24)
                end
            end
        end
    
        -- draw the song data
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
        songDataText.score:draw(songDataX+5, dataBubbleY+5)
        gfx.drawText(currentHiScore, songDataX+5, dataBubbleY+15, fontFamilies.orbeatsSans)
        songDataText.combo:draw(songDataX+5, dataBubbleY+30)
        if currentHiCombo < 0 then
            songDataText.fc:draw(songDataX+5, dataBubbleY+40)
        else
            gfx.drawText(currentHiCombo, songDataX+5, dataBubbleY+40, fontFamilies.orbeatsSans)
        end
        songDataText.rank:draw(songDataX+5, dataBubbleY+55)
        gfx.drawText(currentBestRank, songDataX+5, dataBubbleY+65, fontFamilies.orbeatsSans)
        -- draw the name/artist/bpm bubble
        local bpmTextTable = {currentSong.bpm, "BPM"}
        local bpmText = table.concat(bpmTextTable)
        local nameBubbleWidth = math.max(gfx.getTextSize(currentSong.name, fontFamilies.orbeatsSans)+10, gfx.getTextSize(currentSong.artist, fontFamilies.orbeatsSmall)+gfx.getTextSize(bpmText, fontFamilies. orbeatsSmall)+20)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(songDataX, 30, nameBubbleWidth, 40, 5)
        gfx.drawText(bpmText, songDataX+gfx.getTextSize(currentSong.artist, fontFamilies.orbeatsSmall)+13, 55, fontFamilies.orbeatsSmall)
        gfx.drawText(currentSong.artist, songDataX+5, 55, fontFamilies.orbeatsSmall)
        gfx.drawText(currentSong.name, songDataX+5, 35, fontFamilies.orbeatsSans)
        -- update songDataX
        if songDataX ~= 0 then songDataX = songDataX + math.abs(math.floor(songDataX*0.3)) end
        
        
    
        -- draw the album art
        if selecting == "song" or (selecting == "map" and menuY < menuYPresets.maps) then
            for i=songSelectionRounded+3,songSelectionRounded-3,-1 do
                if i <= #songList and i >= 1 then
                    local filePath = {"songs/", currentSongList[i].folder, "/albumArt.pdi"}
                    local albumArtFilePath = table.concat(filePath)
        
                    local albumPos = -(songSelection-i)*8
        
                    local albumX = screenCenterX + songBarRadius * math.cos(math.rad(albumPos-90)) - albumArtCenter
                    local albumY = songBarY + songBarRadius + songBarRadius * math.sin(math.rad(albumPos-90)) - albumArtCenter
                    -- round the position to the nearest even number so dither doesn't kill anyone
                    albumX = math.floor(albumX/2)*2
                    albumY = math.floor(albumY/2)*2
                    
                    getImage(albumArtFilePath):draw(albumX, albumY)
                end
            end
        end
    
        -- draw the play text
        local textH = 33
        playY = menuY-menuYPresets.play + screenCenterY - textH*0.5
        if playY > -textH then
            if mapExists then
                if currentSong.confirmText ~= nil then
                    local confirmText = currentSong.confirmText[mapList[mapSelectionRounded]]
                    if confirmText ~= nil then
                        local confirmWidth = gfx.getTextSize(confirmText, fontFamilies.odinRounded)
                        gfx.drawText(confirmText, screenCenterX-confirmWidth/2, playY, fontFamilies.odinRounded)
                    else
                        gfx.drawText(playText, screenCenterX-playTextWidth/2, playY, fontFamilies.odinRounded)
                    end
                else
                    gfx.drawText(playText, screenCenterX-playTextWidth/2, playY, fontFamilies.odinRounded)
                end
            else
                gfx.drawText(unavailText, screenCenterX-unavailTextWidth/2, playY, fontFamilies.odinRounded)
            end
            
            
        end
    
        -- draw the pointer
        if pointerY ~= targetPointerY then
            pointerY = math.floor(pointerY + (targetPointerY-pointerY)*0.2)
        end
        pointerSprite:draw(screenCenterX-7, pointerY) 
    
        -- draw menu controls
        local controlsBubbleWidth = 50
        local controlsBubbleHeight = 26
        local controlsYDiff = controlsYPresets.hide - controlsYPresets.show
        local controlsY = controlsYPresets.show + (1-controlsTimer.value)*controlsYDiff
        if drawInputPrompts and selecting ~= "play" then
            -- draw the left controls bubble
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(0, controlsY, controlsBubbleWidth, controlsBubbleHeight, 3)
            gfx.setColor(gfx.kColorBlack)
            gfx.setLineWidth(2)
            gfx.drawRoundRect(0, controlsY, controlsBubbleWidth, controlsBubbleHeight, 3)
            leftControls:draw(4, controlsY+4)
            -- draw the right controls bubble
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(350, controlsY, controlsBubbleWidth, controlsBubbleHeight, 3)
            gfx.setColor(gfx.kColorBlack)
            gfx.setLineWidth(2)
            gfx.drawRoundRect(350, controlsY, controlsBubbleWidth, 26, 3)
            rightControls:draw(355, controlsY+4)
        end
    end
    
    -- draw the sorting bubble and controls ticker
    if drawInputPrompts then
        local selectYDiff = selectYPresets.show - selectYPresets.hide
        local selectBarY = selectYPresets.hide + controlsTimer.value*selectYDiff
        local sortingTextWidth, stw = sortingControls:getSize()
        -- draw the sorting button prompt
        if hasSongs then
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(screenWidth-sortingTextWidth-6, selectBarY, sortingTextWidth+6, 50, 3)
            gfx.setColor(gfx.kColorBlack)
            gfx.setLineWidth(2)
            gfx.drawRoundRect(screenWidth-sortingTextWidth-6, selectBarY, sortingTextWidth+6, 50, 3)
            sortingControls:draw(screenWidth-sortingTextWidth-3, selectBarY+30)
        end
    
        -- draw the up/down controls bar
        if not mapExists and selecting == "play" then
            tickerText = tickerTextBack
            tickerTextWidth = tickerText:getSize()
        end
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, selectBarY, screenWidth, 25)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawLine(0, selectBarY+25, screenWidth, selectBarY+25)
        local tickerX1 = tickerTimer.value
        local tickerX2 = tickerTimer.value-tickerTextWidth
        local tickerX3 = tickerTimer.value+tickerTextWidth
        local padding = 4
        tickerText:draw(tickerX1, selectBarY+padding)
        tickerText:draw(tickerX2, selectBarY+padding)
        tickerText:draw(tickerX3, selectBarY+padding)
        -- gfx.drawText(tickerText, tickerX1, selectBarY+4, fontFamilies.orbeatsSans)
        -- gfx.drawText(tickerText, tickerX2, selectBarY+4, fontFamilies.orbeatsSans)
        -- gfx.drawText(tickerText, tickerX3, selectBarY+4, fontFamilies.orbeatsSans)
    end

    if #songList == 0 then
        drawTextCentered(missingText, screenCenterX, screenCenterY, fontFamilies.odinRounded)
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