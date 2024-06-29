
import "songs"
import "game"

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics
local tmr <const> = pd.timer

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterX <const> = screenWidth / 2
local screenCenterY <const> = screenHeight / 2

-- Define variables
local titleSprite = gfx.image.new("sprites/title")
local bgSprite = {
    gfx.image.new("sprites/titleBg1"),
    gfx.image.new("sprites/titleBg2"),
    gfx.image.new("sprites/titleBg3"),
    gfx.image.new("sprites/titleBg4")
}
local start = false

-- animation variables
local init = true
local jingleBpm = 127
-- pulse vars
local pulse = false
local pulseDepth = 4
-- orbit vars
local orbitCurrentDither = 1
local orbitTargetDither = orbitCurrentDither
local drawOrbit = false
-- title vars
local titleCurrentY = -100
local titleTargetY = titleCurrentY
local titleWidth, titleHeight = titleSprite:getSize("Orbeats", fonts.odinRounded)
local titleX = screenCenterX - (titleWidth/2)
local titleY = screenCenterY - (titleHeight/2)
-- input vars
local inputCurrentY = screenHeight
local inputTargetY = inputCurrentY
-- timing vars
local animStartTime = 0
local audioTime = 0
local lastPulse = 0
local currentBeat = 0
-- misc vars
local fadeOut = 1
local bgStage = 1


local function nextStage()
    bgStage += 1
    if bgStage < 4 then
        tmr.performAfterDelay((1/3)*1000, nextStage)
    end
end


function updateTitle()
    -- init
    if init then
        sfx.jingle:play()
        -- set up bg animation
        tmr.performAfterDelay((1/3)*1000, nextStage)
        -- set up orbit animation
        tmr.performAfterDelay(1500, function()
            drawOrbit = true
        end)
        -- set up title animation
        tmr.performAfterDelay((11/3)*1000, function()
            titleTargetY = titleY            
        end)
        -- set up input prompt animation
        tmr.performAfterDelay(4500, function()
            inputTargetY = 215
        end)
        -- get start time
        animStartTime = pd.sound.getCurrentTime()
        init = false
    end

    -- update the current audio time and current beat
    audioTime = pd.sound.getCurrentTime()
    currentBeat = (audioTime-animStartTime)*(jingleBpm/60)
    print(currentBeat)

    -- calculate if the orbit should pulse
    if math.floor(currentBeat) > lastPulse then
        pulse = true
        lastPulse = math.floor(currentBeat)
    else
        pulse = false
    end

    -- if jingle finished and we're still on the title, start the menu music
    if not sfx.jingle:isPlaying() then
        menuBgm:play(0)
    end

    -- check if any button has been pressed
    if (upPressed or downPressed or leftPressed or rightPressed or aPressed or bPressed) and not start then
        sfx.low:play()
        sfx.jingle:stop()
        start = true
    end

    -- check if we're starting the game
    if start then
        if fadeOut > 0 then
            fadeOut -= 0.1
        else
            -- reset variables
            start = false
            fadeOut = 1
            init = true
            inputCurrentY = screenHeight
            inputTargetY = screenHeight
            titleCurrentY = -100
            titleTargetY = titleCurrentY
            drawOrbit = false
            bgStage = 1
            lastPulse = 0
            return "songSelect"
        end
    end

    return "title"
end

function drawTitle()
    -- draw the black bg
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, screenWidth, screenHeight)

    -- draw the stars on the bg
    bgSprite[bgStage]:draw(0,0)

    -- draw the orbit
    local orbitRadius = 235
    local orbitCenterX = titleX+253
    local orbitCenterY = titleY+72
    if drawOrbit then
        orbitTargetDither = 0.75
        orbitCurrentDither = closeDistance(orbitCurrentDither, orbitTargetDither, 0.3)
        gfx.setColor(gfx.kColorWhite)
        gfx.setDitherPattern(orbitCurrentDither)
        gfx.setLineWidth(7)
        if pulse then
            gfx.drawCircleAtPoint(orbitCenterX, orbitCenterY, orbitRadius-pulseDepth)
        else
            gfx.drawCircleAtPoint(orbitCenterX, orbitCenterY, orbitRadius)
        end
    end

    -- draw the orbit pulse
    local pulseLength = 50
    gfx.setColor(gfx.kColorWhite)
    if drawOrbit then
        gfx.setDitherPattern(orbitCurrentDither+0.25*(currentBeat%1))
        gfx.setLineWidth(7*(1-currentBeat%1))
        gfx.drawCircleAtPoint(orbitCenterX, orbitCenterY, orbitRadius-pulseDepth-pulseLength*(currentBeat%1))
    end

    -- draw the title
    titleCurrentY = closeDistance(titleCurrentY, titleTargetY, 0.1)
    titleSprite:draw(titleX, titleCurrentY)

    -- draw the input prompt
    inputCurrentY = closeDistance(inputCurrentY, inputTargetY, 0.1)
    local inputText = "Press "..char.up.."/"..char.A.." to start"
    local textWidth, textHeight = gfx.getTextSize(inputText, fonts.orbeatsSans)
    local inputX = screenCenterX-(textWidth/2)-3
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(inputX, inputCurrentY, textWidth+6, 30, 3)
    gfx.drawText(inputText, inputX+3, inputCurrentY+5, fonts.orbeatsSans)

    -- draw the fade out if fading out
    if fadeOut < 1 then
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(fadeOut)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    end
end