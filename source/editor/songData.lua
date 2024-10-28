
-- Define constants

local pd <const> = playdate
local gfx <const> = pd.graphics
local kb <const> = pd.keyboard

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterX <const> = screenWidth / 2
local screenCenterY <const> = screenHeight / 2

-- Define variables

local songData = {}

songDataOrder = {
    "name",
    "artist",
    "bpm",
    "bpmChanges",
    "beatOffset",
    "preview",
    "previewTest"
}

songDataLabels = {
    name = "Song Name: ",
    artist = "Song Artist(s): ",
    bpm = "BPM: ",
    bpmChanges = "Set changes to BPM",
    beatOffset = "Beats until first note: ",
    preview = "Preview starts at second: ",
    previewTest = "Listen to preview",
    beat = "Change on beat: ",
    newBpm = "New BPM: ",
    divider = "-------",
    change = "Add BPM change",
    deleteChange = "Delect BPM change"
}

songDataText = {}
bpmChangesText = {}

local function readSongData()
    
    songDataText = {}
    bpmChangesText = {}
    
    songData = editorData[songList[songSelectionRounded]].songData

    for i=1,#songDataOrder do
        if type(songData[songDataOrder[i]]) == "number" or type(songData[songDataOrder[i]]) == "string" then
            table.insert(songDataText, songDataLabels[songDataOrder[i]]..songData[songDataOrder[i]])
        else
            table.insert(songDataText, songDataLabels[songDataOrder[i]])
        end
    end

    if songData.bpmChanges ~= nil then
        for i=1, #songData.bpmChanges do
            table.insert(bpmChangesText, songDataLabels.newBpm..songData.bpmChanges[i].bpm)
            table.insert(bpmChangesText, songDataLabels.beat..songData.bpmChanges[i].beat)
            table.insert(bpmChangesText, songDataLabels.deleteChange)
            table.insert(bpmChangesText, songDataLabels.divider)
        end
    end
    table.insert(bpmChangesText, songDataLabels.change)
end

local init = true

local paramSelection = 1
local oldParamSelection = paramSelection
local editing = false

local bpmParamSelection = 1
local oldBpmParamSelection = bpmParamSelection

local oldText = ""
local cancelled = false

local listenToCrank = false
local changeWhileListening = 0
local oldNum = 0

local music = pd.sound.fileplayer.new()

local selecting = "songData"


function updateSongDataEditor()

    if init then
        readSongData()
        init = false
    end
    
    if selecting == "songData" then
        if not kb.isVisible() and not listenToCrank then
            if bPressed then
                sfx.switch:play()
                music:stop()
                init = true
                pd.datastore.write(editorData, "editorData")
                return "songSelect"
            end
            if aPressed then
                -- handle the keyboard if editing a string
                if type(songData[songDataOrder[paramSelection]]) == "string" then
                    oldText = songData[songDataOrder[paramSelection]]
                    kb.show(oldText)
                    kb.keyboardWillHideCallback = function(confirmed)
                        cancelled = not confirmed
                    end
                    kb.keyboardDidHideCallback = function()
                        if cancelled then
                            editorData[songList[songSelectionRounded]].songData[songDataOrder[paramSelection]] = oldText
                            readSongData()
                        end
                        editing = false
                    end
                end

                -- enable listening for the crank if editing a number
                if type(songData[songDataOrder[paramSelection]]) == "number" then
                    listenToCrank = true
                    oldNum = songData[songDataOrder[paramSelection]]
                end

                editing = true
                sfx.switch:play()

                if songDataOrder[paramSelection] == "previewTest" then
                    -- make the song fade in
                    music:stop()
                    music = pd.sound.fileplayer.new()
                    music:load("/custom audio/"..songList[songSelectionRounded]..".pda")
                    music:setVolume(0.01)
                    music:setVolume(1,1,1)
                    menuBgm:setVolume(0,0,1)
                    music:play()
                    music:setOffset(songData.preview)
                    editing = false
                end

                if songDataOrder[paramSelection] == "bpmChanges" then
                    selecting = "bpmChanges"
                    editing = false
                    bpmParamSelection = 1
                end
            end
            if downPressed then
                paramSelection += 1
            end
            if upPressed then
                paramSelection -= 1
            end
        end
        -- round param selection
        paramSelection = math.min(#songDataText, math.max(paramSelection, 1))
        if oldParamSelection ~= paramSelection then
            sfx.click:play()
            oldParamSelection = paramSelection
        end

        -- update the selected parameter to match what the keyboard has typed
        if kb.isVisible() then
            if type(songData[songDataOrder[paramSelection]]) == "string" then
                editorData[songList[songSelectionRounded]].songData[songDataOrder[paramSelection]] = kb.text
                readSongData()
            end
        end
        
        if listenToCrank then
            if leftPressed then
                changeWhileListening -= 1
                sfx.click:play()
            end
            if rightPressed then
                changeWhileListening += 1
                sfx.click:play()
            end
            changeWhileListening += crankChange/10
            editorData[songList[songSelectionRounded]].songData[songDataOrder[paramSelection]] = math.max(oldNum + round(changeWhileListening), 0)
            readSongData()
            if bPressed then
                sfx.switch:play()
                listenToCrank = false
                changeWhileListening = 0
                editing = false
            end
        end
    else -- if we're selecting from the bpmChanges list
        if not listenToCrank then
            if bPressed then
                sfx.switch:play()
                selecting = "songData"
            end
            if aPressed then
                -- enable listening for the crank if editing a number
                if type(songData.bpmChanges[songDataOrder[paramSelection]]) == "number" then
                    listenToCrank = true
                    oldNum = songData[songDataOrder[paramSelection]]
                end

                editing = true
                sfx.switch:play()
            end
            if downPressed then
                bpmParamSelection += 1
            end
            if upPressed then
                bpmParamSelection -= 1
            end
        end
    end
    
    -- make the song fade out
    if music:getVolume() == 0 then
        music:stop()
    else
        if music:getOffset() >= songData.preview+9 and music:getVolume() == 1 then
            music:setVolume(0,0,1)
        end
    end

    return "songDataEditor"
end

function drawSongDataEditor()
    gfx.clear()
    
    -- draw the list of song data parameters
    drawList(songDataText, paramSelection, 3, 3, 394, 234, 3, fonts.orbeatsSans, not editing, false)

    -- draw the 
end