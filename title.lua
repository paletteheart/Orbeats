
import "songs"
import "game"

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics

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
local delta = 0
local jingleBpm = 127
local tickSpeed = 30
local pulse = false
local pulseDepth = 4
local orbitCurrentDither = 1
local orbitTargetDither = orbitCurrentDither
local titleCurrentY = -100
local titleTargetY = titleCurrentY
local fadeOut = 1
local inputCurrentY = screenHeight
local inputTargetY = inputCurrentY


function updateTitle()
    -- update the delta
    delta += 1

    -- play the jingle
    if delta == 1 then
        sfx.jingle:play()
    end

    -- calculate if the orbit should pulse
    if delta > 50 then
        if delta % math.floor((60*tickSpeed)/jingleBpm) == 0 then
            pulse = true
        else
            pulse = false
        end
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
            start = false
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
    if delta < 10 then
        bgSprite[1]:draw(0,0)
    elseif delta < 20 then
        bgSprite[2]:draw(0,0)
    elseif delta < 30 then
        bgSprite[3]:draw(0,0)
    else
        bgSprite[4]:draw(0,0)
    end

    -- get the title variables
    local titleWidth, titleHeight = titleSprite:getSize("Orbeats", fonts.odinRounded)
    local titleX = screenCenterX - (titleWidth/2)
    local titleY = screenCenterY - (titleHeight/2)

    -- draw the orbit
    local orbitRadius = 235
    local orbitCenterX = titleX+253
    local orbitCenterY = titleY+72
    if delta > 45 then
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
    local fakeCurrentBeat = delta / math.floor((tickSpeed*60)/jingleBpm)
    gfx.setColor(gfx.kColorWhite)
    if delta > 45 then
        gfx.setDitherPattern(orbitCurrentDither+0.25*(fakeCurrentBeat%1))
        gfx.setLineWidth(7*(1-fakeCurrentBeat%1))
        gfx.drawCircleAtPoint(orbitCenterX, orbitCenterY, orbitRadius-pulseDepth-pulseLength*(fakeCurrentBeat%1))
    end

    -- draw the title
    if delta > 110 then
        titleTargetY = titleY
        titleCurrentY = closeDistance(titleCurrentY, titleTargetY, 0.3)
        titleSprite:draw(titleX, titleCurrentY)
    end

    -- draw the input prompt
    if delta > 135 then
        inputTargetY = 215
        inputCurrentY = closeDistance(inputCurrentY, inputTargetY, 0.3)
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