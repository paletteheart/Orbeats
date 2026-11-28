
import "game"

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics
local tmr <const> = pd.timer
local ease <const> = pd.easingFunctions
local menu <const> = pd.getSystemMenu()
local abs <const> = math.abs
local min <const> = math.min
local max <const> = math.max
local floor <const> = math.floor
local rad <const> = math.rad
local sin <const> = math.sin
local cos <const> = math.cos

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
    local mapExists = {}
    local audioFileExists = {}
    for i=#songFolders,1,-1 do
        local songData = json.decodeFile(pd.file.open("songs/"..songFolders[i].."songData.json"))
        songData.folder =  songFolders[i]
        print(songFolders[i])
        table.insert(songList, songData)

        -- cache what maps exist
        for j=#songData.difficulties,1,-1 do
            local mapPath = "songs/"..songFolders[i]..songData.difficulties[j]..".json"
            mapExists[mapPath] = pd.file.exists(mapPath)
        end
        -- cache if the song file exists
        local audioPath = "songs/"..songFolders[i]..songData.name..".pda"
        audioFileExists[audioPath] = pd.file.exists(audioPath)
    end

    return songList, mapExists, audioFileExists
end

local songList <const>, mapExists <const>, audioFileExists <const> = getListOfSongs()

local sortOptions <const> = {
	"artist",
	"name",
	"bpm"
}

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

local tickerTextPlay <const> = gfx.imageWithText("Play:"..char.up.."/"..char.A.." "..char.div.." Back:"..char.down.."/"..char.B.." "..char.div.." ", 400, 400, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSans)
local tickerTextConfirm <const> = gfx.imageWithText("Confirm:"..char.up.."/"..char.A.." "..char.div.." Back:"..char.down.."/"..char.B.." "..char.div.." ", 400, 400, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSans)
local tickerTextBack <const> = gfx.imageWithText("Back:"..char.down.."/"..char.B.." "..char.div.." Back:"..char.down.."/"..char.B.." "..char.div.." ", 400, 400, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSans)

local leftControls <const> = gfx.imageWithText(char.left.."/"..char.ccw, 400, 400, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSans)
local rightControls <const> = gfx.imageWithText(char.right.."/"..char.cw, 400, 400, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSans)
local sortingControls <const> = gfx.imageWithText("Sorting:"..char.menu, 400, 400, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSans)
local modsControls <const> = gfx.imageWithText("Mods:"..char.menu, 400, 400, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSans)
local multText <const> = gfx.imageWithText("Score Mult:", 400, 400, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSmall)

local songDataText <const> = {
    score = gfx.imageWithText("Best Score:", 100, 100, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSmall),
    combo = gfx.imageWithText("Best Combo:", 100, 100, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSmall),
    fc = gfx.imageWithText("Full Combo", 100, 100, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSans),
    ap = gfx.imageWithText("All Perfect", 100, 100, gfx.kColorClear, nil, "oops", kTextAlignment.left, fonts.orbeatsSans),
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

-- Mods constants
local modeOptions <const> = {
    "classic",
    "one button",
    "no crank",
    "o.b. + n.c.",
    "visualizer",
}
local modeMult <const> = {
    1.0,
    0.8,
    0.8,
    0.64,
    0.0
}
local speedOptions <const> = {
    0.75,
    1.0,
    1.5
}
local speedOptionLabels <const> = {
    "75%",
    "100%",
    "150%",
}
local speedMult <const> = {
    0.5,
    1.0,
    1.25,
}
local damageOptions <const> = {
    "normal",
    "no miss",
    "no heal",
    "no fail",
}
local damageMult <const> = {
    1.0,
    1.0,
    1.0,
    0.5,
}

-- Define variables
-- Misc variables

local leftHeldFor = 0 -- a measurement in ticks of how long left has been held
local rightHeldFor = 0 -- a measurement in ticks of how long right has been held
local selecting = "song"

-- Song variables
local currentSongList = {}
currentSong = {}
currentDifficulty = ""
local mapList = {}
if hasSongs then
    if settings.songSorting == sortOptions[1] then
        currentSongList = songListSortedByArtist
    elseif settings.songSorting == sortOptions[2] then
        currentSongList = songListSortedByName
    else
        currentSongList = songListSortedByBpm
    end
    currentSong = currentSongList[1]
    currentDifficulty = currentSong.difficulties[1]
    mapList = currentSong.difficulties
end
songTable = {}
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

local function getInputMode()
    -- check if it's on vizualizer mode
    if settings.autoMode then return modeOptions[5] end
    -- check if it's one button, no crank, or both
    if settings.oneButtonMode then
        if settings.noCrankMode then return modeOptions[4] end
        return modeOptions[2]
    elseif settings.noCrankMode then return modeOptions[3]
    -- if none of the above, it's classic mode
    else return modeOptions[1] end
end

local function getSpeed(option)
    for i=1,#speedOptions do
        if option == speedOptionLabels[i] then return speedOptions[i] end
    end
    return 1.0
end

local function getSpeedLabel(speed)
    for i=1,#speedOptions do
        if speed == speedOptions[i] then return speedOptionLabels[i] end
    end
    return "?"
end

local function isSongFavorited(songFolder)
    local favorited = false

    for i=#settings.favorites,1,-1 do

        if settings.favorites[i] == songFolder then
            favorited = true
            break
        end

    end

    return favorited
end

local function sortSongs()
    if settings.songSorting == sortOptions[1] then
        currentSongList = songListSortedByArtist
    elseif settings.songSorting == sortOptions[2] then
        currentSongList = songListSortedByName
    else
        currentSongList = songListSortedByBpm
    end
end

local function updateScoreMult()
    local mult = 1.0

    local inputMode = getInputMode()
    for i=1,#modeOptions do
        if inputMode == modeOptions[i] then
            mult *= modeMult[i]
            break
        end
    end

    for i=1,#speedOptions do
        if settings.speed == speedOptions[i] then
            mult *= speedMult[i]
            break
        end
    end

    for i=1,#damageOptions do
        if settings.damageMode == damageOptions[i] then
            mult *= damageMult[i]
            break
        end
    end

    setScoreMult(mult)
end

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
    controlsTimer = replaceTimer(controlsTimer, 0, 0.0, 0.0)
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

    playMenuMusic()

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
        else drawInputPrompts = true end
        -- update animations if inputs given
        if leftHeld or rightHeld or upHeld or downHeld or aHeld or bHeld or abs(crankChange) > 0.5 then
            inputTimer = replaceTimer(inputTimer, 4000, function()
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
        if abs(crankChange) < 0.1 or songSelection > #songList or songSelection < 1 then
            songSelection = closeDistance(songSelection, min(#songList, max(1, round(songSelection))), 0.3)
        end
    end

    -- round the songSelection for things that need the exact songSelection
    songSelectionRounded = min(#songList, max(1, round(songSelection)))

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
    if abs(crankChange) < 0.5 or mapSelection > #mapList or mapSelection < 1 or selecting ~= "map" then
        mapSelection = closeDistance(mapSelection, min(#mapList, max(1, round(mapSelection))), 0.3)
    end
    -- round the mapSelection for things that need the exact mapSelection
    mapSelectionRounded = min(#mapList, max(1, round(mapSelection)))
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
                if mapExists[songTablePath] then
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
        local audioPathTable = {musicFile, ".pda"}
        local audioPath = table.concat(audioPathTable)
        if songSelectionRounded == oldSongSelection then
            oldSongSelectionTime += 1
            if oldSongSelectionTime > 15 then
                if audioFileExists[audioPath] then
                    -- make the song fade in
                    if not playedPreview then
                        music = pd.sound.fileplayer.new()
                        music:load(musicFile)
                        music:setVolume(0.01) -- needs to be above 0 for some reason
                        music:setVolume(1,1,1)
                        setMenuMusicVolume(0,1)
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
                            setMenuMusicVolume(1,1)
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
            setMenuMusicVolume(1,1)
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
            stopMenuMusic()
            setUpSong(bpm, bpmChanges, beatOffset, musicFile, songTablePath)
            resetSongSelectAnim()
            songStarting = false

            setGameMenuItems()
            updateScoreMult()

            return "song"
        end
    end

    

    if toMenu then
        -- go back to the main menu
        if fadeBlack > 0 then
            fadeBlack -= 0.1
        else
            resetSongSelectAnim()
            if music:isPlaying() then
                music:stop()
            end
            setMenuMusicVolume(1)
            toMenu = false

            -- reset system menu items
	        menu:removeAllMenuItems()

            return "menu"
        end
    end

    return "songSelect"
end


local sheenX, songBarY
local pathTable, songPath
local mapDistDiff, menuDist
local mapPos, mapX, mapY
local textWidth, textHeight, textX, textY, textFont
local currentHiScore, currentHiCombo, currentBestRank, currentFCStatus, currentAPStatus
local bpmTextTable, bpmText, nameBubbleWidth
local albumPos, albumX, albumY
local playTextH <const> = 33
local confirmText, confirmWidth
local controlsBubbleWidth <const> = 50
local controlsBubbleHeight <const> = 26
local controlsYDiff <const> = controlsYPresets.hide - controlsYPresets.show
local controlsY
local selectYDiff <const> = selectYPresets.show - selectYPresets.hide
local selectBarY, sortingTextWidth, modsTextWidth
local tickerX1, tickerX2, tickerX3
local tickerPadding <const> = 4
local dataBubbleWidth <const> = 100
local dataBubbleHeight <const> = 89
local dataBubbleY <const> = 80
function drawSongSelect()
    -- update the menu Y
    menuY = menuYTimer.value

    -- draw background sheen
    sheenX = sheenTimer.value
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5)
    gfx.setLineWidth(250)
    gfx.drawLine(sheenX, screenHeight+50, sheenX+30, -50)

    -- draw the song bar
    songBarY = menuY + screenHeight - songBarH*0.5
    if selecting == "song" or (selecting == "map" and menuY < menuYPresets.maps) then
        songBarImg:draw(0, songBarY)
    end

    -- check if there are any songs to display
    pathTable = {"songs/", currentSong.folder, mapList[mapSelectionRounded], ".json"}
    songPath = table.concat(pathTable)
    if hasSongs then
        -- draw the difficulty satellites
        if selecting == "map" or (selecting == "play" and menuY < menuYPresets.play) or (selecting == "song" and menuY > menuYPresets.songs) then
            
            -- calculate satellite distance
            mapDistDiff = mapDistPresets.far - mapDistPresets.close
            menuDist = 1-(abs(menuY - menuYPresets.maps)/menuYPresets.maps) -- normalized
            mapDist = mapDistPresets.close + menuDist*mapDistDiff

            mapSelectionOffset = closeDistance(mapSelectionOffset, 0, 0.3)
            for i=mapSelectionRounded+3,mapSelectionRounded-3,-1 do
                if i <= #mapList and i >= 1 then
                    mapPos = (i-mapSelection)*mapDist
                    mapX = screenCenterX + (songBarRadius+200) * cos(rad(mapPos-90))
                    mapY = mapSelectionOffset + menuY - screenCenterY + songBarRadius + songBarRadius * sin(rad(mapPos-90))
                    -- round the position to the nearest even number so dither doesn't kill anyone
                    mapX = floor(mapX/2)*2
                    mapY = floor(mapY/2)*2
    
                    -- draw difficuty name if on the currently selected difficulty
                    if i == mapSelectionRounded then
                        textFont = fontFamilies.orbeatsSans
                        textWidth, textHeight = gfx.getTextSize(mapList[i], textFont)
                        if textWidth > 100 then
                            textFont = fontFamilies.orbeatsSmall
                            textWidth, textHeight = gfx.getTextSize(mapList[i], textFont)
                        end
                        textX = mapX-textWidth/2
                        textY = mapY-textHeight/2+40
                        gfx.setColor(gfx.kColorWhite)
                        gfx.fillRoundRect(textX-2, textY-2, textWidth+4, textHeight+4, 2)
                        gfx.drawText(mapList[i], textX, textY, textFont)
                    end
                
                    -- draw difficulty icon
                    getImage(table.concat({"songs/", currentSong.folder, currentSong.difficulties[i], ".pdi"}), i):draw(mapX-24, mapY-24)
                end
            end
        end
    
        -- draw the song data
        -- draw main data bubble
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(songDataX, dataBubbleY, max(dataBubbleWidth, gfx.getTextSize(currentHiScore, fontFamilies.orbeatsSans)+10), dataBubbleHeight, 5)

        currentHiScore, currentHiCombo, currentBestRank, currentFCStatus, currentAPStatus = getMapRecords(currentSong.name, currentDifficulty)
        
        -- draw the score
        songDataText.score:draw(songDataX+5, dataBubbleY+5)
        gfx.drawText(commaFormat(currentHiScore), songDataX+5, dataBubbleY+15, fontFamilies.orbeatsSans)
        -- draw the combo
        songDataText.combo:draw(songDataX+5, dataBubbleY+32)
        if currentFCStatus then
            if currentAPStatus then       
                songDataText.ap:draw(songDataX+5, dataBubbleY+42)
            else
                songDataText.fc:draw(songDataX+5, dataBubbleY+42)
            end
        else
            gfx.drawText(commaFormat(currentHiCombo), songDataX+5, dataBubbleY+42, fontFamilies.orbeatsSans)
        end
        -- draw the rank
        songDataText.rank:draw(songDataX+5, dataBubbleY+59)
        gfx.drawText(currentBestRank, songDataX+5, dataBubbleY+69, fontFamilies.orbeatsSans)

        -- draw the name/artist/bpm bubble
        bpmTextTable = {currentSong.bpm, "BPM"}
        bpmText = table.concat(bpmTextTable)
        nameBubbleWidth = max(gfx.getTextSize(currentSong.name, fontFamilies.orbeatsSans)+10, gfx.getTextSize(currentSong.artist, fontFamilies.orbeatsSmall)+gfx.getTextSize(bpmText, fontFamilies. orbeatsSmall)+20)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(songDataX, 30, nameBubbleWidth, 40, 5)
        gfx.drawText(bpmText, songDataX+gfx.getTextSize(currentSong.artist, fontFamilies.orbeatsSmall)+13, 55, fontFamilies.orbeatsSmall)
        gfx.drawText(currentSong.artist, songDataX+5, 55, fontFamilies.orbeatsSmall)
        gfx.drawText(currentSong.name, songDataX+5, 35, fontFamilies.orbeatsSans)
        -- update songDataX
        if songDataX ~= 0 then songDataX = songDataX + abs(floor(songDataX*0.3)) end
        
        
    
        -- draw the album art
        if selecting == "song" or (selecting == "map" and menuY < menuYPresets.maps) then
            for i=songSelectionRounded+3,songSelectionRounded-3,-1 do
                if i <= #songList and i >= 1 then
                    albumPos = -(songSelection-i)*8
        
                    albumX = screenCenterX + songBarRadius * cos(rad(albumPos-90)) - albumArtCenter
                    albumY = songBarY + songBarRadius + songBarRadius * sin(rad(albumPos-90)) - albumArtCenter
                    -- round the position to the nearest even number so dither doesn't kill anyone
                    albumX = floor(albumX/2)*2
                    albumY = floor(albumY/2)*2
                    
                    getImage(table.concat({"songs/", currentSongList[i].folder, "/albumArt.pdi"})):draw(albumX, albumY)
                end
            end
        end
    
        -- draw the play text
        playY = menuY-menuYPresets.play + screenCenterY - playTextH*0.5
        if playY > -playTextH then
            if mapExists[songPath] then
                if currentSong.confirmText ~= nil then
                    confirmText = currentSong.confirmText[mapList[mapSelectionRounded]]
                    if confirmText ~= nil then
                        confirmWidth = gfx.getTextSize(confirmText, fontFamilies.odinRounded)
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
            pointerY = floor(pointerY + (targetPointerY-pointerY)*0.2)
        end
        pointerImage:draw(screenCenterX-7, pointerY) 
    
        -- draw menu controls
        controlsY = controlsYPresets.show + (1-controlsTimer.value)*controlsYDiff
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
        selectBarY = selectYPresets.hide + controlsTimer.value*selectYDiff
        sortingTextWidth = sortingControls:getSize()
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
        if not mapExists[songPath] and selecting == "play" then
            tickerText = tickerTextBack
            tickerTextWidth = tickerText:getSize()
        end
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, selectBarY, screenWidth, 25)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawLine(0, selectBarY+25, screenWidth, selectBarY+25)
        tickerX1 = tickerTimer.value
        tickerX2 = tickerTimer.value-tickerTextWidth
        tickerX3 = tickerTimer.value+tickerTextWidth
        tickerText:draw(tickerX1, selectBarY+tickerPadding)
        tickerText:draw(tickerX2, selectBarY+tickerPadding)
        tickerText:draw(tickerX3, selectBarY+tickerPadding)
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
    local integralPart = floor(number)
    local fractionalPart = number - integralPart

    if fractionalPart == 0.5 then
        -- Check if the integral part is even
        if integralPart % 2 == 0 then
            return integralPart  -- Round to the nearest even number
        else
            return floor(number + 0.5)  -- Round up for odd integral part
        end
    else
        return floor(number + 0.5)  -- Round normally for other cases
    end
end

function replaceTimer(timer, ...)
    timer:remove()
    return tmr.new(...)
end

-- System Menu Items Functions

-- sorting items
local function addSortByMenuItem()
	return menu:addOptionsMenuItem("Sort By", sortOptions, settings.songSorting, function(option)
		settings.songSorting = option
	end)
end
local function addFavoritesFirstMenuItem()
    return menu:addCheckmarkMenuItem("Faves First", settings.favoritesFirst, function (checked)
        settings.favoritesFirst = checked
    end)
end
local function addFavoriteMenuItem()
    return menu:addCheckmarkMenuItem("Fave Song", isSongFavorited(currentSong.folder), function (checked)

        for i=#settings.favorites,1,-1 do

            if settings.favorites[i] == currentSong.folder then
                table.remove(settings.favorites, i)
                break
            end

        end

        if checked then
            table.insert(settings.favorites, currentSong.folder)
        end
    end)
end

-- modifier items
local function addModeMenuItem()
	return menu:addOptionsMenuItem("Input", modeOptions, getInputMode(), function (option)
        settings.autoMode, settings.oneButtonMode, settings.noCrankMode = false, false, false

        if option == modeOptions[5] then
            settings.autoMode = true
        elseif option == modeOptions[4] then
            settings.oneButtonMode, settings.noCrankMode = true, true
        elseif option == modeOptions[3] then
            settings.noCrankMode = true
        elseif option == modeOptions[2] then
            settings.oneButtonMode = true
        end
    end)
end
local function addSpeedMenuItem()
    return menu:addOptionsMenuItem("Speed", speedOptionLabels, getSpeedLabel(settings.speed), function (option)
        settings.speed = getSpeed(option)
    end)
end
local function addDamageMenuItem()
    return menu:addOptionsMenuItem("Damage", damageOptions, settings.damageMode, function (option)
        settings.damageMode = option
    end)
end

function setSongSelectMenuItems()
    -- reset system menu items
    menu:removeAllMenuItems()
    if selecting == "song" then
        -- add song sort items
        addSortByMenuItem()
        addFavoritesFirstMenuItem()
        addFavoriteMenuItem()
        sortSongs()
    else
        -- add mods menu items
        addModeMenuItem()
        addDamageMenuItem()
        addSpeedMenuItem()
    end
end