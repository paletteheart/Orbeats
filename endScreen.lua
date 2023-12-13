
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
local songHiScore = 0
local initialized = false

-- Rating variables
local ratingImage = {}
ratingImage.P = gfx.image.new("sprites/ratingP")
ratingImage.SS = gfx.image.new("sprites/ratingSS")
ratingImage.S = gfx.image.new("sprites/ratingS")
ratingImage.A = gfx.image.new("sprites/ratingA")
ratingImage.B = gfx.image.new("sprites/ratingB")
ratingImage.C = gfx.image.new("sprites/ratingC")
ratingImage.D = gfx.image.new("sprites/ratingD")
ratingImage.F = gfx.image.new("sprites/ratingF")
local ratingImageWidth, ratingImageHeight = ratingImage.SS:getSize()
local ratingY = (screenHeight-ratingImageHeight)/2

-- Animation variables
local completedCurrentY = -45
local completedTargetY = 5
local statsCurrentX = -165
local statsTargetX = statsCurrentX
local ratingCurrentX = screenWidth
local ratingTargetX = ratingCurrentX
local continueCurrentY = screenHeight
local continueTargetY = continueCurrentY
local sheenDuration = 600
local fadeOutBlack = 1
local fadeOutWhite = 1
local delta = 0

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
    songHiScore = 0
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

local function resetAnimationValues()
    completedCurrentY = -45
    completedTargetY = 5
    statsCurrentX = -165
    statsTargetX = statsCurrentX
    ratingCurrentX = screenWidth+ratingImage.SS:getSize()
    ratingTargetX = ratingCurrentX
    continueCurrentY = screenHeight+25
    continueTargetY = continueCurrentY
    fadeOutBlack = 1
    fadeOutWhite = 1
    delta = 0
end

function updateEndScreen()
    -- update the delta
    delta += 1
    -- if delta >= sheenDuration+(sheenDuration-400)+60 then delta = 60 end
    -- update the animation variables based on the delta
    if delta > 15 then
        statsTargetX = 15
    end
    if delta > 45 then
        ratingTargetX = screenWidth-ratingImageWidth-5
    end
    if delta > 60 then
        continueTargetY = 215
    end

    -- initialize the end screen
    if not initialized then
        initEndScreen()
        initialized = true
    end

    -- check inputs
    if upPressed or aPressed then
        if delta < 60 then
            delta = 60
        else
            toMenu = true
            restart = false
        end
    end
    if downPressed or bPressed then
        if delta < 60 then
            delta = 60
        else
            restart = true
            toMenu = false
        end
    end

    -- check if they're restarting the song
    if restart then
        if fadeOutWhite > 0 then
            fadeOutWhite -= 0.1
        else
            setUpSong(restartTable.bpm, restartTable.beatOffset, restartTable.musicFilePath, restartTable.tablePath)
            restart = false
            initialized = false
            resetAnimationValues()
            return "song"
        end
    end
    --check if they're going back to the song select menu
    if toMenu then
        if fadeOutBlack > 0 then
            fadeOutBlack -= 0.1
        else
            toMenu = false
            initialized = false
            resetAnimationValues()
            return "songSelect"
        end
    end
    return "songEndScreen"
end

function drawEndScreen()
    -- draw background
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, screenWidth, screenHeight)

    -- draw background sheen
    local sheenX = sheenDuration-(delta%(sheenDuration+(sheenDuration-400)))
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5)
    gfx.setLineWidth(250)
    gfx.drawLine(sheenX, screenHeight+50, sheenX+30, -50)

    -- draw completed text
    completedCurrentY = closeDistance(completedCurrentY, completedTargetY, 0.3)
    gfx.drawText("Song Completed!", 5, completedCurrentY, fonts.odinRounded)

    -- draw stats bubbles
    gfx.setColor(gfx.kColorWhite)
    statsCurrentX = closeDistance(statsCurrentX, statsTargetX, 0.25)
    gfx.fillRoundRect(statsCurrentX, 65, 165, 130, 3)
    -- draw stats
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("Perfect Hits: "..perfectHits, statsCurrentX+5, 70, fonts.orbeatsSans)
    gfx.drawText("Hits: "..hitNotes, statsCurrentX+5, 95, fonts.orbeatsSans)
    gfx.drawText("Misses: "..missedNotes, statsCurrentX+5, 120, fonts.orbeatsSans)
    gfx.drawText("Score: "..score, statsCurrentX+5, 145, fonts.orbeatsSans)
    if songHiScore < score then
        gfx.drawText("New Best Score!", statsCurrentX+5, 170, fonts.orbeatsSans)
    else
        gfx.drawText("Best Score: "..songHiScore, statsCurrentX+5, 170, fonts.orbeatsSans)
    end

    -- draw rating
    ratingCurrentX = closeDistance(ratingCurrentX, ratingTargetX, 0.25)
    if songRating == "P" then
        ratingImage.P:draw(ratingCurrentX, ratingY)
    elseif songRating == "SS" then
        ratingImage.SS:draw(ratingCurrentX, ratingY)
    elseif songRating == "S" then
        ratingImage.S:draw(ratingCurrentX, ratingY)
    elseif songRating == "A" then
        ratingImage.A:draw(ratingCurrentX, ratingY)
    elseif songRating == "B" then
        ratingImage.B:draw(ratingCurrentX, ratingY)
    elseif songRating == "C" then
        ratingImage.C:draw(ratingCurrentX, ratingY)
    elseif songRating == "D" then
        ratingImage.D:draw(ratingCurrentX, ratingY)
    else
        ratingImage.F:draw(ratingCurrentX, ratingY)
    end

    -- draw continue bar
    continueCurrentY = closeDistance(continueCurrentY, continueTargetY, 0.3)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, continueCurrentY, screenWidth, 25)
    -- draw continue text
    local continueText = "Continue:"..char.up.."/"..char.A.." --- Retry:"..char.down.."/"..char.B.." --- "
    local continueTextWidth = gfx.getTextSize(continueText, fonts.orbeatsSans)
    local continueX1 = (delta % (continueTextWidth*3))-continueTextWidth
    local continueX2 = ((delta+continueTextWidth) % (continueTextWidth*3))-continueTextWidth
    local continueX3 = ((delta+(continueTextWidth*2)) % (continueTextWidth*3))-continueTextWidth
    gfx.drawText(continueText, continueX1, continueCurrentY+5, fonts.orbeatsSans)
    gfx.drawText(continueText, continueX2, continueCurrentY+5, fonts.orbeatsSans)
    gfx.drawText(continueText, continueX3, continueCurrentY+5, fonts.orbeatsSans)

    -- draw fade out if fading out
    if fadeOutWhite ~= 1 then
        gfx.setColor(gfx.kColorWhite)
        gfx.setDitherPattern(fadeOutWhite)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    end
    if fadeOutBlack ~= 1 then
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(fadeOutBlack)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    end
end