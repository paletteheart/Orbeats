
-- Define constants
local pd = playdate
local gfx = pd.graphics
local tmr <const> = pd.timer
local ease <const> = pd.easingFunctions

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterX <const> = screenWidth / 2
local screenCenterY <const> = screenHeight / 2

local qrCode = gfx.image.new("sprites/discordCode")
local codeWidth, codeHeight = qrCode:getSize()
local codeX <const> = codeWidth/2 + (screenHeight-codeHeight)/2
local codeHideY <const> = -codeHeight
local codeCurrentY = codeHideY
local codeYTimer = tmr.new(0, codeHideY, codeHideY)

local text = "Join us in the\nOrbeats Discord!\n\nhttps://discord.gg/\nDMwDxVx8gq"
local textWidth, textHeight = gfx.getTextSize(text, fonts.orbeatsSans)
local textX <const> = screenWidth - codeX
local textHideY <const> = screenHeight + textHeight/2
local padding <const> = 5
local textCurrentY = textHideY
local textYTimer = tmr.new(0, textHideY, textHideY)

local floating = 0

local bgScale = tmr.new(0, 0, 0)

local init = true
local exit = false
local fadeOut = 1

local function resetVars()
    codeCurrentY = codeHideY
    textCurrentY = textHideY
    codeYTimer = tmr.new(0, codeHideY, codeHideY)
    textYTimer = tmr.new(0, textHideY, textHideY)
    bgScale = tmr.new(0, 0, 0)
end

function updateDiscordInvite()

    if init then
        resetVars()
        codeYTimer = tmr.new(animationTime*2, codeHideY, screenCenterY, ease.outBack)
        textYTimer = tmr.new(animationTime*2, textHideY, screenCenterY, ease.outBack)
        bgScale = tmr.new(animationTime*2, 0, 1, ease.outCubic)
        init = false
    end

    floating += 0.05

    if aPressed or bPressed or upPressed or downPressed or leftPressed or rightPressed then
        exit = true
    end

    if exit then
        if fadeOut > 0 then
            fadeOut -= 0.1
        else
            exit = false
            fadeOut = 1
            init = true
            resetVars()
            return "menu"
        end
    end
    return "discord"
end

function drawDiscordInvite()

    -- draw the background
    if bgScale.value == 1 then
        bgSprite[4]:draw(0, 0)
    else
        bgSprite[4]:drawScaled(screenCenterX-(screenCenterX*bgScale.value), screenCenterY-(screenCenterY*bgScale.value), bgScale.value)
    end

    -- draw the qr code
    local codeFloating = math.sin(floating)*5
    codeCurrentY = codeYTimer.value
    qrCode:draw(codeX-(codeWidth/2), codeCurrentY-(codeHeight/2)+codeFloating)

    -- draw the invite text
    local textFloating = math.sin(floating-2)*5
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRoundRect(textX-(textWidth/2)-padding, textCurrentY-(textHeight/2)-padding+textFloating, textWidth+padding*2, textHeight+padding*2, padding)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    textCurrentY = textYTimer.value
    drawTextCentered(text, textX, textCurrentY+textFloating, fonts.orbeatsSans)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- draw the fade out
    if fadeOut < 1 then
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(fadeOut)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    end

end