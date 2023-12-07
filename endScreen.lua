
import "game"
import "songs"

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterX <const> = screenWidth / 2
local screenCenterY <const> = screenHeight / 2

-- Define Variables
songRating = ""
local initialized = false

-- Rating variables
local ratingImage = {}
ratingImage.P = gfx.image.new("sprites/ratingP.png")
ratingImage.SS = gfx.image.new("sprites/ratingSS.png")
ratingImage.S = gfx.image.new("sprites/ratingS.png")
ratingImage.A = gfx.image.new("sprites/ratingA.png")
ratingImage.B = gfx.image.new("sprites/ratingB.png")
ratingImage.C = gfx.image.new("sprites/ratingC.png")
ratingImage.D = gfx.image.new("sprites/ratingD.png")
ratingImage.F = gfx.image.new("sprites/ratingF.png")
local ratingImageWidth, ratingImageHeight = ratingImage.SS:getSize()
local ratingX = screenWidth-ratingImageWidth-5
local ratingY = (screenHeight-ratingImageHeight)/2

local function initEndScreen()
    local pointPercentage = score/((hitNotes+missedNotes)*100)

    -- calculate what rating they got
    if pointPercentage == 1 then
        songRating = "P"
    elseif pointPercentage >= 0.9 then
        songRating = "SS"
    elseif pointPercentage >= 0.8 then
        songRating = "S"
    elseif pointPercentage >= 0.7 then
        songRating = "A"
    elseif pointPercentage >= 0.6 then
        songRating = "B"
    elseif pointPercentage >= 0.5 then
        songRating = "C"
    elseif pointPercentage >= 0.4 then
        songRating = "D"
    else
        songRating = "F"
    end

    -- if they got a high score, save it
    local songHiScore = 0
    if scores[currentSong.name] ~= nil then
        if scores[currentSong.name][currentDifficulty] ~= nil then
            songHiScore = scores[currentSong.name][currentDifficulty].score
        else
            scores[currentSong.name][currentDifficulty] = {}
        end
    else
        scores[currentSong.name] = {}
        scores[currentSong.name][currentDifficulty] = {}
    end
    if songHiScore < score then
        scores[currentSong.name][currentDifficulty].score = score
        scores[currentSong.name][currentDifficulty].rating = songRating
        pd.datastore.write(scores, "scores")
    end
end

function updateEndScreen()
    if not initialized then
        initEndScreen()
        initialized = true
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
    gfx.fillRect(0, 0, screenWidth, screenHeight)

    gfx.drawText("Song Completed!", 5, 5, fonts.odinRounded)

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(15, 65, ratingX-20, 130, 3)

    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("Perfect Hits: "..perfectHits, 20, 75, fonts.orbeatsSans)
    gfx.drawText("Hits: "..hitNotes, 20, 105, fonts.orbeatsSans)
    gfx.drawText("Misses: "..missedNotes, 20, 135, fonts.orbeatsSans)
    gfx.drawText("Score: "..score, 20, 165, fonts.orbeatsSans)

    if songRating == "P" then
        ratingImage.P:draw(ratingX, ratingY)
    elseif songRating == "SS" then
        ratingImage.SS:draw(ratingX, ratingY)
    elseif songRating == "S" then
        ratingImage.S:draw(ratingX, ratingY)
    elseif songRating == "A" then
        ratingImage.A:draw(ratingX, ratingY)
    elseif songRating == "B" then
        ratingImage.B:draw(ratingX, ratingY)
    elseif songRating == "C" then
        ratingImage.C:draw(ratingX, ratingY)
    elseif songRating == "D" then
        ratingImage.D:draw(ratingX, ratingY)
    else
        ratingImage.F:draw(ratingX, ratingY)
    end

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 215, screenWidth, 25)

    local continueText = "Continue:"..char.up.."/"..char.A.." --- Retry:"..char.down.."/"..char.B.." --- "
    local continueTextWidth = gfx.getTextSize(continueText, fonts.orbeatsSans)
    gfx.drawText(continueText, 2, 220, fonts.orbeatsSans)
    gfx.drawText(continueText, 2+continueTextWidth, 220, fonts.orbeatsSans)
end