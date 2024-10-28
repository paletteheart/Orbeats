
import "CoreLibs/keyboard"

import "editor/songs"
import "editor/songData"

-- define constants
local pd <const> = playdate
local gfx <const> = pd.graphics
local tmr <const> = pd.timer
local ease <const> = pd.easingFunctions


-- define variables

local editorState = "songSelect"

local manualMenuImage = gfx.image.new(400, 240)
gfx.pushContext(manualMenuImage)
    qrCode:draw(230, 50)
gfx.popContext()

function updateLevelEditor()
    -- fade out bgm
    if menuBgm:isPlaying() then
        menuBgm:setVolume(0, 0, 1)
        if menuBgm:getVolume() == 0 then
            menuBgm:stop()
        end
    end


    if editorState == "songSelect" then
        editorState = updateEditorSongsSelect()
        pd.setMenuImage(manualMenuImage, 200)
    elseif editorState == "songDataEditor" then
        editorState = updateSongDataEditor()
    elseif editorState == "exitEditor" then
        pd.setMenuImage(nil)
        editorState = "songSelect"
        return "menu"
    end
    
    return "levelEditor"
end

function drawLevelEditor()

    if editorState == "songSelect" then
        drawEditorSongSelect()
    elseif editorState == "songDataEditor" then
        drawSongDataEditor()
    end

end