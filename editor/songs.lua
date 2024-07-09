
-- Define constants

local pd <const> = playdate
local gfx <const> = pd.graphics

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterX <const> = screenWidth / 2
local screenCenterY <const> = screenHeight / 2

local songOptions <const> = {
    "Set Data",
    "Edit Maps",
    "Export",
    "Delete"
}

local mapOptions <const> = {
    "New Map",
    "Edit Chart",
    "Rename",
    "Duplicate",
    "Delete"
}

local guideText <const> = "Read the online level editor manual\nto get started making your own levels!"

local drawerHeaders = {
    songs = "Songs",
    maps = "Maps"
}

-- define variables
local function getListOfSongs()
    local songFiles = pd.file.listFiles("/custom songs/")

    for i=#songFiles,1,-1 do
        if songFiles[i]:sub(-4) ~= '.pda' then
            table.remove(songFiles, i)
        else
            songFiles[i] = songFiles[i]:sub(1, -5)
            print(songFiles[i])
        end
    end

    return songFiles
end

local songList = getListOfSongs()

qrCode = gfx.image.new("sprites/manualCode")

editorData = pd.datastore.read("editorData")
if editorData == nil then editorData = {} end

local selecting = "song"

local songSelection = 1
local songSelectionRounded = songSelection
local oldSongSelection = songSelection

local songOptionSelection = 1
local songOptionSelectionRounded = songOptionSelection
local oldSongOptionSelection = songOptionSelection

local deleting = false


local function truncateString(string, width, font)
    local stringWidth = gfx.getTextSize(string, font)
    local newString = string

    while stringWidth > width do
        if newString:sub(-3) == "..." then
            newString = newString:sub(1, newString:len()-4).."..."
        else
            newString = newString:sub(1, newString:len()-1).."..."
        end
        stringWidth = gfx.getTextSize(newString, font)
    end

    return newString
end


function updateEditorSongsSelect()

    if not deleting then
        if selecting == "song" then
            if bPressed or leftPressed then
                sfx.low:play()
                return "exitEditor"
            end
            if aPressed or rightPressed then
                sfx.switch:play()
                selecting = "songOption"
            end
            if downPressed then
                songSelection = songSelectionRounded+1
            end
            if upPressed then
                songSelection = songSelectionRounded-1
            end
            songSelection += crankChange/90
        elseif selecting == "songOption" then
            if bPressed or leftPressed then
                sfx.switch:play()
                selecting = "song"
            end
            if aPressed or rightPressed then
                if songOptions[songOptionSelectionRounded] == "Delete" then
                    deleting = true
                    sfx.switch:play()
                elseif songOptions[songOptionSelectionRounded] == "Set Data" then
                    sfx.switch:play()
                    return "songDataEditor"
                end
            end
            if downPressed then
                songOptionSelection = songOptionSelectionRounded+1
            end
            if upPressed then
                songOptionSelection = songOptionSelectionRounded-1
            end
            songOptionSelection += crankChange/90
        end
    else
        if aHeld and upHeld then
            pd.file.delete("/custom songs/"..songList[songSelectionRounded]..".pda")
            songList = getListOfSongs()
            deleting = false
            sfx.play:play()
        end
        if bPressed or downPressed or leftPressed or rightPressed then
            deleting = false
            sfx.switch:play()
        end
    end
    -- round song selection
    songSelection = math.min(#songList, math.max(songSelection, 1))
    songSelectionRounded = round(songSelection)
    if oldSongSelection ~= songSelectionRounded then
        sfx.click:play()
        oldSongSelection = songSelectionRounded
    end
    -- round song option selection
    songOptionSelection = math.min(#songOptions, math.max(songOptionSelection, 1))
    songOptionSelectionRounded = round(songOptionSelection)
    if oldSongOptionSelection ~= songOptionSelectionRounded then
        sfx.click:play()
        oldSongOptionSelection = songOptionSelectionRounded
    end

    return "songSelect"
end

function drawEditorSongSelect()
    gfx.clear(gfx.kColorBlack)
    
    -- draw the manual code if no songs are detected
    if #songList == 0 then
        local codeX, codeY = screenCenterX-70, screenCenterY-100


        qrCode:draw(codeX, codeY)
        local textWidth, textHeight = gfx.getTextSize(guideText, fonts.orbeatsSans)
        local textX, textY = screenCenterX, screenCenterY+70
        local padding = 3
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(textX-textWidth/2-padding, textY-padding, textWidth+padding*2, textHeight+padding*2, 2)
        gfx.setFont(fonts.orbeatsSans)
        gfx.drawTextAligned(guideText, textX, textY, kTextAlignment.center)
    else

        -- draw the songs drawer
        local songHeaderX, songHeaderY = 3, 3
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText(drawerHeaders.songs, songHeaderX, songHeaderY, fonts.orbeatsSans)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)

        gfx.setColor(gfx.kColorWhite)
        gfx.setLineWidth(2)
        gfx.drawLine(133, 0, 133, screenHeight)

        -- draw the list of songs
        if selecting == "song" then
            drawScrollingList(songList, songSelectionRounded, 12, 22, 110, 216, 3, fonts.orbeatsSans, true, true)
        else
            drawScrollingList(songList, songSelectionRounded, 12, 22, 110, 216, 3, fonts.orbeatsSans, false, true)
        end

        -- draw the second drawer
        gfx.setColor(gfx.kColorWhite)
        gfx.setLineWidth(2)
        gfx.drawLine(267, 0, 267, screenHeight)

        if selecting == "song" or selecting == "songOption" then
            if selecting == "songOption" then
                drawScrollingList(songOptions, songOptionSelectionRounded, 136, 3, 110, 216, 3, fonts.orbeatsSans, true, true)
            else
                drawScrollingList(songOptions, songOptionSelectionRounded, 136, 3, 110, 216, 3, fonts.orbeatsSans, false, true)
            end
        else

        end

    end

    if deleting then
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(0.5)
        gfx.fillRect(0, 0, screenWidth, screenHeight)

        local deletingWhat = "song"
        if selecting == "mapOption" then
            deletingWhat = "map"
        end
        local warningText = "Are you sure you want to\ndelete this "..deletingWhat.."?\nPress "..char.A.." and "..char.up.." to confirm,\nanything else to cancel."
        local textWidth, textHeight = gfx.getTextSize(warningText, fonts.orbeatsSans)
        local textX, textY = screenCenterX-textWidth/2, screenCenterY-textHeight/2
        local padding = 5
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(textX-padding, textY-padding, textWidth+padding*2, textHeight+padding*2, 3)
        gfx.setFont(fonts.orbeatsSans)
        gfx.drawTextAligned(warningText, screenCenterX, textY, kTextAlignment.center)
    end

end

function drawScrollingList(list, selectedItem, x, y, width, height, padding, font, fill, invert)
    local textHeight = font[playdate.graphics.font.kVariantNormal]:getHeight()
    local maxItems = math.floor(height/(textHeight+padding))
    for i=math.max(selectedItem-maxItems/2+1, 1),#list do
        local textY = y+(textHeight+padding)*(math.min(i, i-selectedItem+maxItems/2)-1)+padding
        local textX = x+padding
        
        local truncatedText = truncateString(list[i], width, font)
        local selectBoxColor = gfx.kColorBlack
        local selectedTextColor = gfx.kDrawModeInverted
        local textColor = gfx.kDrawModeCopy
        if invert then
            selectBoxColor = gfx.kColorWhite
            selectedTextColor = gfx.kDrawModeCopy
            textColor = gfx.kDrawModeInverted
        end
        if selectedItem == i then
            local textWidth = gfx.getTextSize(truncatedText, font)
            gfx.setColor(selectBoxColor)
            if fill then
                gfx.fillRoundRect(textX-padding, textY-padding, textWidth+padding*2, textHeight+padding*2, 3)
                gfx.setImageDrawMode(selectedTextColor)
                gfx.drawText(truncatedText, textX, textY, font)
            else
                gfx.drawRoundRect(textX-padding, textY-padding, textWidth+padding*2, textHeight+padding*2, 3)
                gfx.setImageDrawMode(textColor)
                gfx.drawText(truncatedText, textX, textY, font)
            end
        else
            gfx.setImageDrawMode(textColor)
            gfx.drawText(truncatedText, textX, textY, font)
        end
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end