
-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics
local tmr <const> = pd.timer
local ease <const> = pd.easingFunctions

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterX <const> = screenWidth / 2
local screenCenterY <const> = screenHeight / 2

local titleImage <const> = gfx.image.new("sprites/title")
local titleImageBackup <const> = gfx.image.new("sprites/title")
local titleWidth <const>, titleHeight <const> = titleImage:getSize()
local titleX <const> = screenCenterX - (titleWidth/2)
local titleY <const> = screenCenterY - (titleHeight/2)

local function createTitlePieces()
    local masks = {}

    masks[1] = gfx.image.new(37, titleHeight)
    gfx.pushContext(masks[1])
        titleImage:draw(0, 0)
    gfx.popContext()

    masks[2] = gfx.image.new(62, titleHeight)
    gfx.pushContext(masks[2])
        titleImage:draw(0, 0)
    gfx.popContext()

    masks[3] = gfx.image.new(102, titleHeight)
    gfx.pushContext(masks[3])
        titleImage:draw(0, 0)
    gfx.popContext()

    masks[4] = gfx.image.new(139, titleHeight)
    gfx.pushContext(masks[4])
        titleImage:draw(0, 0)
    gfx.popContext()

    masks[5] = gfx.image.new(179, titleHeight)
    gfx.pushContext(masks[5])
        titleImage:draw(0, 0)
    gfx.popContext()

    masks[6] = gfx.image.new(204, titleHeight)
    gfx.pushContext(masks[6])
        titleImage:draw(0, 0)
    gfx.popContext()

    return masks
end
local titlePieces = createTitlePieces()
local titlePieceBackups = createTitlePieces()
local pieceTiming <const> = {14.25, 14.5, 15, 15.25, 15.5, 15.75, 16}
local showInputBeat <const> = 17

bgmIntro = pd.sound.fileplayer.new("bgm/intro")

local function getSplashes()
    local list = pd.file.listFiles("/splashes/")
    local imgs = {}
    for i=1, #list do
        imgs[i] = gfx.image.new("/splashes/"..i..".pdi")
    end
    return imgs
end
local splashes = getSplashes()

-- Define variables
bgImage = gfx.image.new("sprites/stars2")
local bgDither = 0
local bgDitherTimer = tmr.new(0)
local start = false

-- animation variables
local init = true
local menuBpm <const> = 126
-- pulse vars
local pulse = false
local pulseDepth = 4
local pulseTimer = 0
-- title vars
local drawTitle = false
local titlePiece = 0
-- orbit vars
local orbitDither = 1
local orbitDitherTimer = tmr.new(0, orbitDither, orbitDither)
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
-- parallax vars
local accel = {}
local oldAccel = {}
local accelChange = {}
local smoothAccel = {}
local recentAccel = {x = {}, y = {}}
local parallax = {x = 0, y = 0}
local bgParallaxMult <const> = 13
local titleParallaxMult <const> = 40
-- misc vars
local fadeOut = 1
local fadeIn = 0

local function sign(number)
    return number > 0 and 1 or (number == 0 and 0 or -1)
end

local function trunc(number)
    if sign(number) > 0 then
        return math.floor(number*100)*0.01
    elseif sign(number) < 0 then
        return math.ceil(number*100)*0.01
    else
        return number
    end
end

function updateTitleScreen()
   playMenuMusic()

    -- init
    if init then
        bgDitherTimer = tmr.new(4300, 0, 1)
        -- set up orbit animation
        orbitDitherTimer = tmr.new(4300, orbitDither, 0.75)
        -- get start time
        animStartTime = pd.sound.getCurrentTime()
        init = false
    end

    -- update the accelerometer and parallax effect
    if not pd.accelerometerIsRunning() then
        pd.startAccelerometer()
        oldAccel.x, oldAccel.y = pd.readAccelerometer()
    end

    -- push to the center
    parallax.x = trunc(parallax.x - 0.002*sign(parallax.x))
    parallax.y = trunc(parallax.y - 0.002*sign(parallax.y))

    -- read the accelerometer
    accel.x, accel.y = pd.readAccelerometer()
    -- smooth the accelerometer values
    table.insert(recentAccel.x, accel.x)
    table.insert(recentAccel.y, accel.y)
    if #recentAccel.x > 5 then
        table.remove(recentAccel.x, 1)
        table.remove(recentAccel.y, 1)
    end
    smoothAccel = {x = 0, y = 0}
    for i = 1, #recentAccel.x do
        smoothAccel.x += recentAccel.x[i]
        smoothAccel.y += recentAccel.y[i]
    end
    smoothAccel.x /= #recentAccel.x
    smoothAccel.y /= #recentAccel.y

    accelChange.x = trunc(smoothAccel.x-oldAccel.x)
    accelChange.y = trunc(smoothAccel.y-oldAccel.y)
    parallax.x += accelChange.x
    parallax.y += accelChange.y

    oldAccel = smoothAccel


    -- update the current audio time and current beat
    audioTime = pd.sound.getCurrentTime()
    currentBeat = (audioTime-animStartTime)*(menuBpm/60)

    -- update the current title piece shown
    if titlePiece ~= nil then
        if currentBeat >= pieceTiming[titlePiece+1] then
            drawTitle = true
            titlePiece += 1
            if titlePiece > #titlePieces then titlePiece = nil end
        end
    end
    
    -- update the input prompt animation
    if currentBeat >= showInputBeat and drawInput == false then
        drawInput = true
        inputYTimer = tmr.new(animationTime, screenHeight, inputY, ease.outCubic)
    end

    -- calculate if the orbit should pulse
    if drawInput then
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
    end

    -- check if any button has been pressed
    if (upPressed or downPressed or leftPressed or rightPressed or aPressed or bPressed) and not start then
        sfx.mid:play()
        sfx.jingle:stop()
        start = true
    end

    -- orbit radius toy
    orbitRadius = math.min(orbitMaxRadius, math.max(orbitMinRadius, orbitRadius+(crankChange/5)))

    if fadeIn < 1 then
        fadeIn += 0.1
    end

    -- check if we're starting the game
    if start then
        if fadeOut > 0 then
            fadeOut -= 0.1
        else
            start = false
            fadeOut = 1
            fadeIn = 0
            -- end animation if necessary
            if bgDitherTimer ~= nil then
                bgDitherTimer = tmr.new(0, 1, 1)
                orbitDitherTimer = tmr.new(0, 0.75, 0.75)
                bgDitherTimer:remove()
                orbitDitherTimer:remove()
            end
            if not drawInput then
                drawInput = true
                inputYTimer = tmr.new(0, inputY, inputY)
            end
            titlePiece = nil
            drawTitle = true
            -- free up memory
            titlePieces = nil
            titlePieceBackups = nil
            pd.stopAccelerometer()
            return "menu"
        end
    end

    return "title"
end

function drawTitleScreen()

    -- draw the stars on the bg
    bgDither = bgDitherTimer.value
    gfx.setStencilPattern(bgDither)
    bgImage:draw(-(parallax.x*bgParallaxMult),-(parallax.y*bgParallaxMult))
    gfx.clearStencil()

    -- draw the orbit
    local titleParallax = {
        x = parallax.x*titleParallaxMult,
        y = parallax.y*titleParallaxMult
    }
    orbitDither = orbitDitherTimer.value
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(orbitDither)
    gfx.setLineWidth(5)
    if pulse then
        gfx.drawCircleAtPoint(orbitCenterX-titleParallax.x, orbitCenterY-titleParallax.y, orbitRadius-pulseDepth)
    else
        gfx.drawCircleAtPoint(orbitCenterX-titleParallax.x, orbitCenterY-titleParallax.y, orbitRadius)
    end

    -- draw the orbit pulse
    local pulseLength = 50
    if drawInput then
        gfx.setColor(gfx.kColorWhite)
        gfx.setDitherPattern(orbitDither+0.25*(currentBeat%1))
        gfx.setLineWidth(7*(1-currentBeat%1))
        gfx.drawCircleAtPoint(orbitCenterX, orbitCenterY, orbitRadius-pulseDepth-pulseLength*(currentBeat%1))
    end

    if drawTitle then
        --draw the title mask
        local currentTitle
        local currentBackup
        if titlePiece ~= nil then
            currentTitle = titlePieces[titlePiece]
            currentBackup = titlePieceBackups[titlePiece]
        else
            currentTitle = titleImage
            currentBackup = titleImageBackup
        end
        local titleMask = currentBackup:getMaskImage()
        gfx.pushContext(currentTitle)
            -- reset the sprite
            currentBackup:draw(0, 0)

            
            gfx.setColor(gfx.kColorBlack)
            if drawInput then
                -- draw the shadow of the pulse
                gfx.setLineWidth(7*(1-currentBeat%1))
                gfx.drawCircleAtPoint(orbitCenterX-titleX, orbitCenterY-titleY, orbitRadius-pulseDepth-pulseLength*(currentBeat%1))
            end

            
            -- draw the cut of the orbit
            -- gfx.setColor(gfx.kColorWhite)
            gfx.setLineWidth(3)
            if pulse then
                gfx.drawCircleAtPoint(orbitCenterX-titleX, orbitCenterY-titleY, orbitRadius-pulseDepth)
                gfx.setLineWidth(1)
                gfx.setColor(gfx.kColorWhite)
                gfx.drawCircleAtPoint(orbitCenterX-titleX, orbitCenterY-titleY, orbitRadius-pulseDepth+2)
                gfx.drawCircleAtPoint(orbitCenterX-titleX, orbitCenterY-titleY, orbitRadius-pulseDepth-2)
            else
                gfx.drawCircleAtPoint(orbitCenterX-titleX, orbitCenterY-titleY, orbitRadius)
                gfx.setLineWidth(1)
                gfx.setColor(gfx.kColorWhite)
                gfx.drawCircleAtPoint(orbitCenterX-titleX, orbitCenterY-titleY, orbitRadius+2)
                gfx.drawCircleAtPoint(orbitCenterX-titleX, orbitCenterY-titleY, orbitRadius-2)
            end
        gfx.popContext()
        currentTitle:setMaskImage(titleMask)

        -- draw the title
        currentTitle:draw(titleX-titleParallax.x, titleY-titleParallax.y)
    end

    -- draw the input prompt
    if drawInput then
        inputCurrentY = inputYTimer.value
        local inputText = "Press "..char.up.."/"..char.A.." to start"
        local textWidth, textHeight = gfx.getTextSize(inputText, fontFamilies.orbeatsSans)
        local inputX = screenCenterX-(textWidth/2)-3
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(inputX, inputCurrentY, textWidth+6, 30, 3)
        gfx.drawText(inputText, inputX+3, inputCurrentY+5, fontFamilies.orbeatsSans)
    end

    -- draw the fade out if fading out
    if fadeOut < 1 then
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(fadeOut)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    end
    -- draw the fade in if fading in
    if fadeIn < 1 then
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(fadeIn)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    end
end

local currentSplash = 1
local splashTime <const> = 4
local transitionTime <const> = 0.4
local splashTimer = tmr.new(splashTime*1000, 0, splashTime)
local splashFade = 1
local titleDelay

function updateSplashes()
    -- if splashTimer == nil then splashTimer = tmr.new(splashTime*1000, 0, splashTime) end
    if splashTimer.value == splashTime or buttonPressed then
        currentSplash += 1
        splashTimer = tmr.new(splashTime*1000, 0, splashTime)
        -- splashTimer:start()
    end

    if splashTimer.value < transitionTime then
        splashFade = splashTimer.value/transitionTime
    elseif splashTimer.value > splashTime-transitionTime then
        splashFade = math.abs(splashTimer.value-splashTime)/transitionTime
    else splashFade = 1 end

    if currentSplash > #splashes then
        if titleDelay == nil then
            titleDelay = tmr.new(transitionTime*1000)
        elseif titleDelay.currentTime == transitionTime*1000 then
            splashes = nil -- free up the memory
            return "title"
        end
    end
    return "splash"
end

function drawSplashes()
    if currentSplash > # splashes then return end
    gfx.setStencilPattern(splashFade)

    splashes[currentSplash]:draw(0, 0)

    gfx.clearStencil()
end