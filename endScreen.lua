
import "game"

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics

-- Define Variables
local maxNotes = 0
local pointPercentage = 0
local ratingSprite = gfx.sprite.new()
ratingSprite:moveTo(0, 0)
local ratingImage = {}
ratingImage.p = gfx.image.new("sprites/ratingP.png")
ratingImage.ss = gfx.image.new("sprites/ratingSS.png")
ratingImage.s = gfx.image.new("sprites/ratingS.png")
ratingImage.a = gfx.image.new("sprites/ratingA.png")
ratingImage.b = gfx.image.new("sprites/ratingB.png")
ratingImage.c = gfx.image.new("sprites/ratingC.png")
ratingImage.d = gfx.image.new("sprites/ratingD.png")
ratingImage.e = gfx.image.new("sprites/ratingE.png")
ratingImage.f = gfx.image.new("sprites/ratingF.png")

function updateEndScreen()
    maxNotes = hitNotes+missedNotes
    pointPercentage = score/(maxNotes*100)

    if pointPercentage == 1 then
        ratingSprite:setImage(ratingImage.p)
    elseif pointPercentage >= 0.9 then
        ratingSprite:setImage(ratingImage.ss)
    elseif pointPercentage >= 0.8 then
        ratingSprite:setImage(ratingImage.s)
    elseif pointPercentage >= 0.7 then
        ratingSprite:setImage(ratingImage.a)
    elseif pointPercentage >= 0.6 then
        ratingSprite:setImage(ratingImage.b)
    end

    --check if they're going back to the song select menu
    if toMenu then
        toMenu = false
        return "songSelect"
    end
    return "songEndScreen"
end

function drawEndScreen()
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("Song Completed!", 5, 5, fonts.odinRounded)
    gfx.drawText("Hit Notes: "..hitNotes, 20, 60, fonts.orbeatsSans)
    gfx.drawText("Missed Notes: "..missedNotes, 20, 80, fonts.orbeatsSans)
    gfx.drawText("Score: "..score, 20, 100, fonts.orbeatsSans)

    
end