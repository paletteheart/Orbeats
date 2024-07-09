
-- Define constants
local pd = playdate
local gfx = pd.graphics

local warning = "Warning!"
local warningDesc = "This will delete all your high scores,\nall your stats, reset your current\nsettings, and reboot the game.\nIf you're sure about this, press and\nhold "..char.up.." and "..char.A.." at once.\nPress anything else to go back."
local warningPattern = {0x78, 0x3C, 0x1E, 0xF, 0x87, 0xC3, 0xE1, 0xF0}

function updateResetMenu()
    
    if downPressed or leftPressed or rightPressed or bPressed then
        return "settings"
    end

    if upHeld and aHeld then
        pd.datastore.delete("scores")
        stats = {}
        pd.datastore.delete("stats")
        pd.datastore.delete("settings")
        pd.restart()
    end

    return "reset"
end

function drawResetMenu()
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(9)
    gfx.drawRect(50, 20, 300, 200)
    gfx.setPattern(warningPattern)
    gfx.setLineWidth(5)
    gfx.drawRect(50, 20, 300, 200)
    drawTextCentered(warning, 200, 50, fonts.odinRounded)
    gfx.setFont(fonts.orbeatsSans)
    gfx.drawTextAligned(warningDesc, 200, 100, kTextAlignment.center)
end