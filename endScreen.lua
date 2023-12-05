
import "game"

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics

function updateEndScreen()
    --check if they're going back to the song select menu
    if toMenu then
        toMenu = false
        return "songSelect"
    end
    return "songEndScreen"
end

function drawEndScreen()
    gfx.setColor(gfx.kColorBlack)
    gfx.drawTextAligned("Song Over!", 200, 2, kTextAlignment.center)
    gfx.drawTextAligned("Score: "..score, 200, 32, kTextAlignment.center)
    gfx.drawTextAligned("Hit Notes: "..hitNotes, 200, 62, kTextAlignment.center)
    gfx.drawTextAligned("Missed Notes: "..missedNotes, 200, 92, kTextAlignment.center)
end