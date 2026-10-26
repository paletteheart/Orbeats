

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics
local tmr <const> = pd.timer
local ease <const> = pd.easingFunctions

local screenWidth <const> = 400
local screenHeight <const> = 240

local wheelDither <const> = {0xFF, 0xDD, 0xFF, 0x77, 0xFF, 0xDD, 0xFF, 0x77}
local planetDither <const> = {0x0, 0x3C, 0x5A, 0x7E, 0x5A, 0x66, 0x3C, 0x0}

local menuItems <const> = {
    "basics",
    "basics2",
    "basics3",
    "basics4",
    "advanced"
}
local menuItemNames <const> = {
    "Basic Controls & Notes",
    "Flipping & Flip Notes",
    "Slide Notes",
    "Hold & Release Notes",
    "Advanced Note Patterns"
}

local tutorialIcon <const> = gfx.image.new("sprites/tutorialSelect.pdi")
local iconWidth <const>, iconHeight <const> = tutorialIcon:getSize()
-- local rotatedPointer <const> = pointerSprite:rotatedImage(-90)

-- Define vars
local init = false

local tutorialStarting = false

local menuSelection = 1
local menuSelectionRounded = menuSelection
local oldSelection = menuSelection

local leavingMenu = false
local fadeBlack = 1
local fadeWhite = 1

local wheelXRadius = 100
local wheelYRadius = 50
local wheelYRadiusTimer = tmr.new(0, wheelYRadius, wheelYRadius)
local wheelY = 450
local wheelYTimer = tmr.new(0, wheelY, wheelY)

local sheenTimer = tmr.new(0, 600, 600)

local inputXTimer = tmr.new(0, 0, 0)
local drawInputPrompts = true
local promptTimer = tmr.new(0, 0, 0)
local startHideAnimation = true

local floating = 0



local function resetAnim()
    wheelY = 450
    wheelYTimer = replaceTimer(wheelYTimer, 500, wheelY, screenHeight, ease.outBack)
    wheelYRadius = 50
    wheelYRadiusTimer = replaceTimer(wheelYRadiusTimer, 500, wheelYRadius, 150, ease.outBack)
    sheenTimer = replaceTimer(sheenTimer, 20000, 600, -200)
    sheenTimer.repeats = true
    inputXTimer = replaceTimer(inputXTimer, animationTime, -0.1, 1, ease.outBack)
    startHideAnimation = true
end

function updateTutorialSelect()
    
    -- initialize animations
    if not init then
        resetAnim()
        init = true
    end

    -- play bgm if not already
    if not menuBgm:isPlaying() then
        menuBgm:play(0)
        menuBgm:setVolume(1)
    end

    -- update floating elements' animations
    floating += 0.05
    if floating == 1 then floating = 0 end
    
    -- check inputs
    -- check back inputs
    if downPressed or bPressed then
        if tutorialStarting then
            tutorialStarting = false
            wheelYRadiusTimer = replaceTimer(wheelYRadiusTimer, animationTime, wheelYRadius, 150, ease.outCubic)
            sfx.mid:play()
        else
            leavingMenu = true
            wheelYRadiusTimer = replaceTimer(wheelYRadiusTimer, animationTime, wheelYRadius, 50, ease.outCubic)
            wheelYTimer = replaceTimer(wheelYTimer, 500, wheelY, 450, ease.outCubic)
            sfx.low:play()
        end
    end
    -- check confirm inputs
    if upPressed or aPressed then
        if leavingMenu then
            leavingMenu = false
            wheelYRadiusTimer = replaceTimer(wheelYRadiusTimer, animationTime, wheelYRadius, 150, ease.outCubic)
            wheelYTimer = replaceTimer(wheelYTimer, 500, wheelY, screenHeight, ease.outBack)
            sfx.mid:play()
        else
            tutorialStarting = true
            wheelYRadiusTimer = replaceTimer(wheelYRadiusTimer, animationTime, wheelYRadius, 300, ease.outCubic)
            sfx.play:play()
        end
    end
    -- check selection inputs
    if rightPressed then
        menuSelection = round(menuSelection)-0.51
    end
    if leftPressed then
        menuSelection = round(menuSelection)+0.51
    end
    menuSelection -= crankChange/90
    -- loop selection
    if menuSelection > #menuItems+0.5 then
        menuSelection -= #menuItems
    elseif menuSelection < 0.5 then
        menuSelection += #menuItems
    end
    -- round selection
    if math.abs(crankChange) < 0.5 then
        menuSelection = closeDistance(menuSelection, math.min(#menuItems, math.max(1, round(menuSelection))), 0.3)
    end
    menuSelectionRounded = round(menuSelection)
    if oldSelection ~= menuSelectionRounded then
        sfx.switch:play()
        oldSelection = menuSelectionRounded
    end

    -- set up timers for input prompts when recieving inputs
    if leftHeld or rightHeld or upHeld or downHeld or math.abs(crankChange) > 0.5 then
        promptTimer = replaceTimer(promptTimer, 4000, function()
            drawInputPrompts = true
            inputXTimer = replaceTimer(inputXTimer, animationTime, -0.1, 1, ease.outBack)
            startHideAnimation = true
        end)

        if inputXTimer.value == 0 then
            drawInputPrompts = false
        end
        if startHideAnimation then
            inputXTimer = replaceTimer(inputXTimer, animationTime, 1, -0.1, ease.inBack)
            startHideAnimation = false
        end
    end

    -- check for leaving the menu
    if tutorialStarting then
        -- get the map file path
        local songTablePath = "tutorial/"..menuItems[menuSelectionRounded]..".json"
        -- check if the map exists, do nothing if not
        if not pd.file.exists(songTablePath) then
            songStarting = false
        else
            -- fade out and then load map
            if fadeWhite > 0 then
                fadeWhite -= 0.1
            else
                local tutorialData = json.decodeFile(pd.file.open("tutorial/songData.json"))
                local bpm = tutorialData.bpm
                local bpmChanges = tutorialData.bpmChanges
                local beatOffset = tutorialData.beatOffset
                if music:isPlaying() then
                    music:stop()
                end
                menuBgm:stop()
                local tutorialMusicFile = ("tutorial/"..menuItems[menuSelectionRounded])
                setUpSong(bpm, bpmChanges, beatOffset, tutorialMusicFile, songTablePath)
                tutorialStarting = false
                settings.tutorialPlayed = true
                pd.datastore.write(settings, "settings")
                resetSongSelectAnim()
                init = false
                tutorial = true
                return "song"
            end
        end
    elseif leavingMenu then
        -- go to destination
        if fadeBlack > 0 then
            fadeBlack -= 0.1
        else
            leavingMenu = false
            init = false
            return "menu"
        end
    else
        fadeBlack = 1
        fadeWhite = 1
    end

    return "tutorialSelect"
end


function drawTutorialSelect()
    -- draw background
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, screenWidth, screenHeight)

    -- draw background sheen
    local sheenX = sheenTimer.value
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5)
    gfx.setLineWidth(250)
    gfx.drawLine(sheenX, screenHeight+50, sheenX+30, -50)


    --draw planet
    gfx.setPattern(planetDither)
    gfx.fillCircleAtPoint(screenWidth, wheelY, wheelYRadius)
    gfx.setColor(gfx.kColorWhite)
    gfx.setLineWidth(5)
    gfx.drawCircleAtPoint(screenWidth, wheelY, wheelYRadius)

    -- draw wheel
    wheelY = wheelYTimer.value
    wheelYRadius = wheelYRadiusTimer.value
    wheelXRadius = wheelYRadius*2
    gfx.setPattern(wheelDither)
    -- gfx.setColor(gfx.kColorWhite)
    -- gfx.setDitherPattern(0.25)
    local yScale = 0.7
    local ringSize
    ringSize = 30
    gfx.setLineWidth(6)
    gfx.drawEllipseInRect(screenWidth-wheelXRadius-ringSize, wheelY-wheelYRadius-ringSize*yScale, (wheelXRadius+ringSize)*2, (wheelYRadius+ringSize*yScale)*2)
    ringSize = 20
    gfx.setLineWidth(2)
    gfx.drawEllipseInRect(screenWidth-wheelXRadius-ringSize, wheelY-wheelYRadius-ringSize*yScale, (wheelXRadius+ringSize)*2, (wheelYRadius+ringSize*yScale)*2)
    ringSize = 10
    gfx.setLineWidth(10)
    gfx.drawEllipseInRect(screenWidth-wheelXRadius-ringSize, wheelY-wheelYRadius-ringSize*yScale, (wheelXRadius+ringSize)*2, (wheelYRadius+ringSize*yScale)*2)
    ringSize = -10
    gfx.setLineWidth(14)
    gfx.drawEllipseInRect(screenWidth-wheelXRadius-ringSize, wheelY-wheelYRadius-ringSize*yScale, (wheelXRadius+ringSize)*2, (wheelYRadius+ringSize*yScale)*2)
    ringSize = -25
    gfx.setLineWidth(5)
    gfx.drawEllipseInRect(screenWidth-wheelXRadius-ringSize, wheelY-wheelYRadius-ringSize*yScale, (wheelXRadius+ringSize)*2, (wheelYRadius+ringSize*yScale)*2)

    -- draw floating icon
    local iconFloat = math.sin(floating)*5
    local iconAngle = -40
    local iconX = screenWidth + (wheelXRadius*1.6) * math.cos(math.rad(iconAngle-90)) - iconWidth/2
    local iconY = wheelY + (wheelYRadius*1.6) * math.sin(math.rad(iconAngle-90)) - iconHeight/2
    tutorialIcon:draw(iconX, iconY+iconFloat)

    -- draw menu item icons
    gfx.setLineWidth(1)
    for i=1,#menuItems do

        local itemPos = (menuSelection-i)*(135/#menuItems)-30

        -- draw menu item names
        local textWidth, textHeight = gfx.getTextSize(menuItemNames[i], fontFamilies.orbeatsSans)
        local textX = screenWidth + wheelXRadius * math.cos(math.rad(itemPos-90)) - textWidth/2
        local textY = wheelY + wheelYRadius * math.sin(math.rad(itemPos-90)) - textHeight/2
        local padding = 3
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(textX-padding, textY-padding, textWidth+padding*2, textHeight+padding*2, 2)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRoundRect(textX-padding, textY-padding, textWidth+padding*2, textHeight+padding*2, 2)
        gfx.drawText(menuItemNames[i], textX, textY, fontFamilies.orbeatsSans)
        -- draw the pointer on the current selection
        if i == menuSelectionRounded then
            pointerSprite:draw(textX, textY-17-padding*2)
        end
    end

    
    -- draw the input prompts
    local inputX = inputXTimer.value

    if drawInputPrompts then
        local padding = 3
        local roundedness = 3
        local inputY = 3
        -- draw the left prompts
        -- draw the back prompt
        local inputTextWidth, inputTextHeight = gfx.getTextSize(inputText.back, fontFamilies.orbeatsSans)
        local inputXScaled = (inputX-1)*(inputTextWidth+padding*2)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(inputXScaled, inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(inputXScaled, inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
        gfx.drawText(inputText.back, inputXScaled+padding, inputY+padding, fontFamilies.orbeatsSans)
        -- draw the left direction prompt
        inputTextWidth, inputTextHeight = gfx.getTextSize(inputText.left, fontFamilies.orbeatsSans)
        inputXScaled = (inputX-1)*(inputTextWidth+padding*2)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(inputXScaled, inputTextHeight+padding*2+inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(inputXScaled, inputTextHeight+padding*2+inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
        gfx.drawText(inputText.left, inputXScaled+padding, inputY+inputTextHeight+padding*3, fontFamilies.orbeatsSans)


        -- draw the right prompts
        -- draw the confirm prompt
        inputTextWidth, inputTextHeight = gfx.getTextSize(inputText.confirm, fontFamilies.orbeatsSans)
        inputXScaled = screenWidth-inputX*(inputTextWidth+padding*2)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(inputXScaled, inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(inputXScaled, inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
        gfx.drawText(inputText.confirm, inputXScaled+padding, inputY+padding, fontFamilies.orbeatsSans)
        -- draw the right direction prompt
        inputTextWidth, inputTextHeight = gfx.getTextSize(inputText.right, fontFamilies.orbeatsSans)
        inputXScaled = screenWidth-inputX*(inputTextWidth+padding*2)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(inputXScaled, inputTextHeight+padding*2+inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(inputXScaled, inputTextHeight+padding*2+inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
        gfx.drawText(inputText.right, inputXScaled+padding, inputY+inputTextHeight+padding*3, fontFamilies.orbeatsSans)
    end

    -- draw fade out
    if fadeBlack ~= 1 then
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(fadeBlack)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    end
    if fadeWhite ~= 1 then
        gfx.setColor(gfx.kColorWhite)
        gfx.setDitherPattern(fadeWhite)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    end
end