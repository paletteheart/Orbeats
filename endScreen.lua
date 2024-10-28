
-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics
local tmr <const> = pd.timer
local ease <const> = pd.easingFunctions

local screenWidth <const> = 400
local screenHeight <const> = 240

-- Define Variables
songRating = ""
local songHiScore = 0
local songHiCombo = 0
local fullCombo = false
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
local fullComboImage = gfx.image.new("sprites/fullCombo")
local ratingImageWidth, ratingImageHeight = ratingImage.SS:getSize()
local ratingY = (screenHeight-ratingImageHeight)/2

-- Animation variables
local completedCurrentY = -45
local completedYTimer = tmr.new(0, completedCurrentY, completedCurrentY)

local statsCurrentX = -165
local statsXTimer = tmr.new(0, statsCurrentX, statsCurrentX)

local ratingCurrentX = screenWidth
local ratingXTimer = tmr.new(0, ratingCurrentX, ratingCurrentX)

local continueCurrentY = screenHeight
local continueYTimer = tmr.new(0, continueCurrentY, continueCurrentY)
local bgmTimer
local tickerTimer = tmr.new(0, 0, 0)
tickerTimer.repeats = true
local tickerText = "To Menu:"..char.up.."/"..char.A.." --- Retry:"..char.down.."/"..char.B.." --- "
local tickerTextWidth = gfx.getTextSize(tickerText, fonts.orbeatsSans)

local sheenTimer = tmr.new(0, 600, 600)
sheenTimer.repeats = true

local fadeOutBlack = 1
local fadeOutWhite = 1

local function initEndScreen()
    local pointPercentage = score/((hitNotes+missedNotes+notesLeft)*100)

    -- set up animations
    completedYTimer = replaceTimer(completedYTimer, animationTime, completedCurrentY, 5, ease.outCubic)
    tmr.new(500, function()
        statsXTimer = replaceTimer(statsXTimer, animationTime, statsCurrentX, 15, ease.outCubic)
    end)
    tmr.new(1500, function()
        ratingXTimer = replaceTimer(ratingXTimer, animationTime, ratingCurrentX, screenWidth-ratingImageWidth-5, ease.outCubic)
    end)
    bgmTimer = tmr.new(2000, function()
        continueYTimer = replaceTimer(continueYTimer, animationTime, continueCurrentY, 215, ease.outCubic)
        menuBgm:play(0)
        menuBgm:setVolume(1)
    end)

    sheenTimer = replaceTimer(sheenTimer, 20000, 600, -200)
    sheenTimer.repeats = true
    tickerTimer = replaceTimer(tickerTimer, 7500, 0, tickerTextWidth)
    tickerTimer.repeats = true

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

    -- check if they got a full combo
    if missedNotes == 0 then
        fullCombo = true
    else
        fullCombo = false
    end

    -- if they got a high score, save it
    songHiScore = 0
    songHiCombo = 0
    if scores ~= nil then
        if scores[currentSong.name] ~= nil then
            if scores[currentSong.name][currentDifficulty] ~= nil then
                songHiScore = scores[currentSong.name][currentDifficulty].score
                songHiCombo = scores[currentSong.name][currentDifficulty].combo
            else
                scores[currentSong.name][currentDifficulty] = {}
            end
        else
            scores[currentSong.name] = {}
            scores[currentSong.name][currentDifficulty] = {}
        end
    else
        scores = {}
        scores[currentSong.name] = {}
        scores[currentSong.name][currentDifficulty] = {}
    end
    if songHiScore == nil then
        songHiScore = 0
    end
    if songHiCombo == nil then
        songHiCombo = 0
    end
    
    if songHiScore < score then
        scores[currentSong.name][currentDifficulty].score = score
        scores[currentSong.name][currentDifficulty].rating = songRating
    end
    if songHiCombo < largestCombo then
        scores[currentSong.name][currentDifficulty].combo = largestCombo
        scores[currentSong.name][currentDifficulty].fc = fullCombo
    end
    
    pd.datastore.write(scores, "scores")

    -- update stats
    if stats.lifetimeScore ~= nil then
        stats.lifetimeScore += score
    else
        stats.lifetimeScore = score
    end

    if stats.hitNotes ~= nil then
        stats.hitNotes += hitNotes
    else
        stats.hitNotes = hitNotes
    end
    
    if stats.perfectHits ~= nil then
        stats.perfectHits += perfectHits
    else
        stats.perfectHits = perfectHits
    end

    if stats.missedNotes ~= nil then
        stats.missedNotes += missedNotes
    else
        stats.missedNotes = missedNotes
    end

    if stats.levelsCompleted ~= nil then
        stats.levelsCompleted += 1
    else
        stats.levelsCompleted = 1
    end

    if fullCombo then
        if stats.fullCombos ~= nil then
            stats.fullCombos += 1
        else
            stats.fullCombos = 1
        end
    end

    if stats.ranksReceived == nil then
        stats.ranksReceived = {}
    end

    if stats.ranksReceived[songRating] ~= nil then
        stats.ranksReceived[songRating] += 1
    else
        stats.ranksReceived[songRating] = 1
    end

    pd.datastore.write(stats, "stats")
end

local function resetAnimationValues()
    sheenTimer = replaceTimer(sheenTimer, 0, 600, 600)
    completedCurrentY = -45
    completedYTimer = replaceTimer(completedYTimer, 0, completedCurrentY, completedCurrentY)
    statsCurrentX = -165
    statsXTimer = replaceTimer(statsXTimer, 0, statsCurrentX, statsCurrentX)
    ratingCurrentX = screenWidth+ratingImage.SS:getSize()
    ratingXTimer = replaceTimer(ratingXTimer, 0, ratingCurrentX, ratingCurrentX)
    continueCurrentY = screenHeight+25
    continueYTimer = replaceTimer(continueYTimer, 0, continueCurrentY, continueCurrentY)
    fadeOutBlack = 1
    fadeOutWhite = 1
end

function updateEndScreen()

    -- initialize the end screen
    if not initialized then
        initEndScreen()
        initialized = true
    end

    -- check inputs
    if upPressed or aPressed then
        toMenu = true
        restart = false
        sfx.low:play()
    end
    if downPressed or bPressed then
        restart = true
        toMenu = false
        sfx.low:play()
    end

    -- check if they're restarting the song
    if restart then
        if fadeOutWhite > 0 then
            fadeOutWhite -= 0.1
        else
            setUpSong(restartTable.bpm, restartTable.bpmChanges, restartTable.beatOffset, restartTable.musicFilePath, restartTable.tablePath)
            restart = false
            initialized = false
            bgmTimer:remove()
            if menuBgm:isPlaying() then
                menuBgm:stop()
            end
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

    -- draw background sheen
    local sheenX = sheenTimer.value
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5)
    gfx.setLineWidth(250)
    gfx.drawLine(sheenX, screenHeight+50, sheenX+30, -50)

    -- draw completed text
    completedCurrentY = completedYTimer.value
    if failed then
        gfx.drawText("Song Failed.", 5, completedCurrentY, fonts.odinRounded)
    else
        gfx.drawText("Song Completed!", 5, completedCurrentY, fonts.odinRounded)
    end

    -- draw stats bubbles
    local statsY = 55
    gfx.setColor(gfx.kColorWhite)
    statsCurrentX = statsXTimer.value
    gfx.fillRoundRect(statsCurrentX, statsY, 165, 155, 3)
    -- draw stats
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("Perfect Hits: "..perfectHits, statsCurrentX+5, statsY+5, fonts.orbeatsSans)
    gfx.drawText("Hits: "..hitNotes, statsCurrentX+5, statsY+30, fonts.orbeatsSans)
    gfx.drawText("Misses: "..missedNotes, statsCurrentX+5, statsY+55, fonts.orbeatsSans)

    gfx.drawText("Combo: "..largestCombo, statsCurrentX+5, statsY+80, fonts.orbeatsSans)
    if songHiCombo < largestCombo then
        gfx.drawText("New Best Combo!", statsCurrentX+5, statsY+100, fonts.orbeatsSmall)
    else
        gfx.drawText("Best Combo: "..songHiCombo, statsCurrentX+5, statsY+100, fonts.orbeatsSmall)
    end

    gfx.drawText("Score: "..score, statsCurrentX+5, statsY+120, fonts.orbeatsSans)
    if songHiScore < score then
        gfx.drawText("New Best Score!", statsCurrentX+5, statsY+140, fonts.orbeatsSmall)
    else
        gfx.drawText("Best Score: "..songHiScore, statsCurrentX+5, statsY+140, fonts.orbeatsSmall)
    end

    -- draw rating
    ratingCurrentX = ratingXTimer.value
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

    -- draw full combo sprite if full combo
    if fullCombo then
        fullComboImage:draw(ratingCurrentX+33, ratingY+95)
    end

    -- draw continue bar
    continueCurrentY = continueYTimer.value
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, continueCurrentY, screenWidth, 25)
    -- draw continue text
    local tickerX1 = tickerTimer.value
    local tickerX2 = tickerTimer.value-tickerTextWidth
    local tickerX3 = tickerTimer.value+tickerTextWidth
    gfx.drawText(tickerText, tickerX1, continueCurrentY+5, fonts.orbeatsSans)
    gfx.drawText(tickerText, tickerX2, continueCurrentY+5, fonts.orbeatsSans)
    gfx.drawText(tickerText, tickerX3, continueCurrentY+5, fonts.orbeatsSans)

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