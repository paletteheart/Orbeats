
-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics
local tmr <const> = pd.timer
local ease <const> = pd.easingFunctions

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterX <const> = screenWidth / 2
local screenCenterY <const> = screenHeight / 2

-- Define variables
local titleSprite = gfx.image.new("sprites/title")
local titleSpriteBackup = gfx.image.new("sprites/title")
bgSprite = {
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
local pulseTimer = 0
-- title vars
local titleHideX = -300
local titleCurrentX = titleHideX
local titleXTimer = tmr.new(0, titleHideX, titleHideX)
local titleWidth, titleHeight = titleSprite:getSize("Orbeats", fonts.odinRounded)
local titleX <const> = screenCenterX - (titleWidth/2)
local titleY <const> = screenCenterY - (titleHeight/2)
local drawTitle = false
-- orbit vars
local orbitDither = 1
local orbitDitherTimer = tmr.new(0, orbitDither, orbitDither)
local drawOrbit = false
local orbitRadius = 235
local orbitMinRadius <const>, orbitMaxRadius <const> = 25, 300
local orbitCenterX <const> = titleX+249
local orbitCenterY <const> = titleY+72
-- input vars
local inputCurrentY = screenHeight
local inputY = 215
local inputYTimer = tmr.new(0, screenHeight, screenHeight)
local drawInput = false
-- timing vars
local animStartTime = 0
local audioTime = 0
local lastPulse = 0
local currentBeat = 0
-- misc vars
local fadeOut = 1
local bgStage = 1

local function resetVars()
    -- reset variables
    inputCurrentY = screenHeight
    titleCurrentX = titleHideX
    pulseTimer = 0
    drawOrbit = false
    drawTitle = false
    drawInput = false
    orbitDither = 1
    bgStage = 1
    lastPulse = 0
    orbitRadius = 235

    -- reset all timers
    local timers = tmr.allTimers()
    for i=1,#timers do
        timers[i]:remove()
    end
end

local function nextStage()
    bgStage = math.min(bgStage+1, 4)
    if bgStage < 4 then
        tmr.performAfterDelay((1/3)*1000, nextStage)
    end
end


function updateTitleScreen()
    -- init
    if init then
        sfx.jingle:play()
        -- set up bg animation
        tmr.performAfterDelay((1/3)*1000, nextStage)
        -- set up orbit animation
        tmr.performAfterDelay(1500, function()
            drawOrbit = true
            orbitDitherTimer = tmr.new(animationTime, orbitDither, 0.75)
        end)
        -- set up title animation
        tmr.performAfterDelay((11/3)*1000, function()
            drawTitle = true
            titleXTimer = tmr.new(500, titleHideX, titleX, ease.outBack)
        end)
        -- set up input prompt animation
        tmr.performAfterDelay(4500, function()
            drawInput = true
            inputYTimer = tmr.new(animationTime, screenHeight, inputY, ease.outCubic)
        end)
        -- get start time
        animStartTime = pd.sound.getCurrentTime()
        init = false
    end

    -- update the current audio time and current beat
    audioTime = pd.sound.getCurrentTime()
    currentBeat = (audioTime-animStartTime)*(jingleBpm/60)

    -- calculate if the orbit should pulse
    if math.floor(currentBeat) > lastPulse then
        pulse = true
        lastPulse = math.floor(currentBeat)
    else
        if pulseTimer == 4 then
            pulse = false
            pulseTimer = 0
        else
            pulseTimer += 1
        end
    end

    -- if jingle finished and we're still on the title, start the menu music
    if not sfx.jingle:isPlaying() then
        menuBgm:play(0)
        menuBgm:setVolume(1)
    end

    -- check if any button has been pressed
    if (upPressed or downPressed or leftPressed or rightPressed or aPressed or bPressed) and not start then
        sfx.mid:play()
        sfx.jingle:stop()
        start = true
    end

    -- orbit radius toy
    orbitRadius = math.min(orbitMaxRadius, math.max(orbitMinRadius, orbitRadius+(crankChange/5)))

    -- check if we're starting the game
    if start then
        if fadeOut > 0 then
            fadeOut -= 0.1
        else
            start = false
            fadeOut = 1
            init = true
            resetVars()
            return "menu"
        end
    end

    return "title"
end

function drawTitleScreen()

    -- draw the stars on the bg
    bgSprite[bgStage]:draw(0,0)

    -- draw the orbit
    if drawOrbit then
        orbitDither = orbitDitherTimer.value
        gfx.setColor(gfx.kColorWhite)
        gfx.setDitherPattern(orbitDither)
        gfx.setLineWidth(5)
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
        gfx.setDitherPattern(orbitDither+0.25*(currentBeat%1))
        gfx.setLineWidth(7*(1-currentBeat%1))
        gfx.drawCircleAtPoint(orbitCenterX, orbitCenterY, orbitRadius-pulseDepth-pulseLength*(currentBeat%1))
    end

    --draw the title mask
    local titleMask = titleSpriteBackup:getMaskImage()
    gfx.pushContext(titleSprite)
        -- reset the sprite
        titleSpriteBackup:draw(0, 0)

        -- draw the shadow of the pulse
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(7*(1-currentBeat%1))
        gfx.drawCircleAtPoint(orbitCenterX-titleCurrentX, orbitCenterY-titleY, orbitRadius-pulseDepth-pulseLength*(currentBeat%1))

        
        -- draw the cut of the orbit
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(5)
        if pulse then
            gfx.drawCircleAtPoint(orbitCenterX-titleCurrentX, orbitCenterY-titleY, orbitRadius-pulseDepth)
            gfx.setLineWidth(1)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawCircleAtPoint(orbitCenterX-titleCurrentX, orbitCenterY-titleY, orbitRadius-pulseDepth+2)
            gfx.drawCircleAtPoint(orbitCenterX-titleCurrentX, orbitCenterY-titleY, orbitRadius-pulseDepth-2)
        else
            gfx.drawCircleAtPoint(orbitCenterX-titleCurrentX, orbitCenterY-titleY, orbitRadius)
            gfx.setLineWidth(1)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawCircleAtPoint(orbitCenterX-titleCurrentX, orbitCenterY-titleY, orbitRadius+2)
            gfx.drawCircleAtPoint(orbitCenterX-titleCurrentX, orbitCenterY-titleY, orbitRadius-2)
        end
    gfx.popContext()
    titleSprite:setMaskImage(titleMask)

    -- draw the title
    if drawTitle then
        titleCurrentX = titleXTimer.value
        titleSprite:draw(titleCurrentX, titleY)
    end

    -- draw the input prompt
    if drawInput then
        inputCurrentY = inputYTimer.value
        local inputText = "Press "..char.up.."/"..char.A.." to start"
        local textWidth, textHeight = gfx.getTextSize(inputText, fonts.orbeatsSans)
        local inputX = screenCenterX-(textWidth/2)-3
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(inputX, inputCurrentY, textWidth+6, 30, 3)
        gfx.drawText(inputText, inputX+3, inputCurrentY+5, fonts.orbeatsSans)
    end

    -- draw the fade out if fading out
    if fadeOut < 1 then
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(fadeOut)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    end
end