
-- Define constants

local pd <const> = playdate
local gfx <const> = pd.graphics

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterX <const> = screenWidth / 2
local screenCenterY <const> = screenHeight / 2

-- Define variables




function updateSongDataEditor()
    
    if bPressed then
        sfx.switch:play()
        return "songSelect"
    end

    return "songDataEditor"
end

function drawSongDataEditor()
    gfx.clear()
    
end