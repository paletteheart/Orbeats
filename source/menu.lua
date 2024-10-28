
-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics
local tmr <const> = pd.timer
local ease <const> = pd.easingFunctions

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterX <const> = screenWidth / 2

local wheelDither <const> = {0xAA, 0x0, 0x80, 0x0, 0x80, 0x0, 0x80, 0x0}

local menuItems <const> = {
    "tutorial",
    "songSelect",
    "settings",
    "stats",
    "levelEditor"
}
local menuItemNames <const> = {
    "Tutorial",
    "Songs",
    "Settings",
    "Stats",
    "Level Editor"
}

-- Define vars
local init = false

local tutorialStarting = false

local menuSelection = 2
if not settings.tutorialPlayed then
    menuSelection = 1
end
local menuSelectionRounded = menuSelection
local oldSelection = menuSelection

local toTitle = false
local leavingMenu = false
local fadeBlack = 1
local fadeWhite = 1

local wheelRadius = 50
local wheelRadiusTimer = tmr.new(0, wheelRadius, wheelRadius)
local wheelY = 450
local wheelYTimer = tmr.new(0, wheelY, wheelY)

local sheenTimer = tmr.new(0, 600, 600)

inputText = {
    left = char.left.."/"..char.ccw,
    right = char.right.."/"..char.cw,
    confirm = "Confirm:"..char.up.."/"..char.A,
    back = "Back:"..char.down.."/"..char.B,
    select = "Select:"..char.left.."/"..char.right.."/"..char.A,
    save = "Save and Exit:"..char.B,
    scroll = "Scroll:"..char.down.."/"..char.cw.."/"..char.up.."/"..char.ccw
}
local inputXTimer = tmr.new(0, 0, 0)
local drawInputPrompts = true
local promptTimer = tmr.new(0, 0, 0)
local startHideAnimation = true



local function resetAnim()
    wheelY = 450
    wheelYTimer = replaceTimer(wheelYTimer, 500, wheelY, screenHeight, ease.outBack)
    wheelRadius = 50
    wheelRadiusTimer = replaceTimer(wheelRadiusTimer, 500, wheelRadius, 150, ease.outBack)
    sheenTimer = replaceTimer(sheenTimer, 20000, 600, -200)
    sheenTimer.repeats = true
    inputXTimer = replaceTimer(inputXTimer, animationTime, -0.1, 1, ease.outBack)
    startHideAnimation = true
end

function updateMainMenu()
    
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
    
    -- check inputs
    -- check back inputs
    if downPressed or bPressed then
        if leavingMenu then
            leavingMenu = false
            wheelRadiusTimer = replaceTimer(wheelRadiusTimer, animationTime, wheelRadius, 150, ease.outCubic)
            sfx.mid:play()
        else
            toTitle = true
            wheelRadiusTimer = replaceTimer(wheelRadiusTimer, animationTime, wheelRadius, 50, ease.outCubic)
            wheelYTimer = replaceTimer(wheelYTimer, 500, wheelY, 450, ease.outCubic)
            sfx.low:play()
        end
    end
    -- check confirm inputs
    if upPressed or aPressed then
        if toTitle then
            toTitle = false
            wheelRadiusTimer = replaceTimer(wheelRadiusTimer, animationTime, wheelRadius, 150, ease.outCubic)
            wheelYTimer = replaceTimer(wheelYTimer, 500, wheelY, screenHeight, ease.outBack)
            sfx.mid:play()
        else
            if menuItems[menuSelectionRounded] == "tutorial" then
                tutorialStarting = true
            else
                leavingMenu = true
            end
            wheelRadiusTimer = replaceTimer(wheelRadiusTimer, animationTime, wheelRadius, 300, ease.outCubic)
            sfx.play:play()
        end
    end
    -- check selection inputs
    if leftPressed then
        menuSelection = round(menuSelection)-0.51
    end
    if rightPressed then
        menuSelection = round(menuSelection)+0.51
    end
    menuSelection += crankChange/90
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
        local songTablePath = "tutorial/Tutorial.json"
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
                local bpmChanges = tutorialData.bpmChange
                local beatOffset = tutorialData.beatOffset
                if music:isPlaying() then
                    music:stop()
                end
                menuBgm:stop()
                local tutorialMusicFile = ("tutorial/Tutorial")
                setUpSong(bpm, bpmChanges, beatOffset, tutorialMusicFile, songTablePath)
                tutorialStarting = false
                settings.tutorialPlayed = true
                pd.datastore.write(settings, "settings")
                resetSongSelectAnim()
                init = false
                return "song"
            end
        end
    elseif toTitle then
        -- go back to the title screen
        if fadeBlack > 0 then
            fadeBlack -= 0.1
        else
            menuBgm:stop()
            toTitle = false
            init = false
            return "title"
        end

    elseif leavingMenu then
        -- go to destination
        if fadeBlack > 0 then
            fadeBlack -= 0.1
        else
            leavingMenu = false
            init = false
            return menuItems[menuSelectionRounded]
        end
    else
        fadeBlack = 1
        fadeWhite = 1
    end

    return "menu"
end


function drawMainMenu()
    -- draw background
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, screenWidth, screenHeight)

    -- draw background sheen
    local sheenX = sheenTimer.value
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5)
    gfx.setLineWidth(250)
    gfx.drawLine(sheenX, screenHeight+50, sheenX+30, -50)

    -- draw wheel
    wheelY = wheelYTimer.value
    wheelRadius = wheelRadiusTimer.value
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(screenCenterX, wheelY, wheelRadius)
    gfx.setColor(gfx.kColorBlack)
    -- gfx.setDitherPattern(1/3, gfx.image.kDitherTypeDiagonalLine)
    gfx.setPattern(wheelDither)
    gfx.fillCircleAtPoint(screenCenterX, wheelY, wheelRadius)
    gfx.setColor(gfx.kColorWhite)
    gfx.setLineWidth(5)
    gfx.drawCircleAtPoint(screenCenterX, wheelY, wheelRadius)

    -- draw menu item icons
    for i=1,#menuItems do
        local itemArtFilePath = "sprites/"..menuItems[i]..".pdi"

        local itemPos = -(menuSelection-i)*(360/#menuItems)

        local itemX = screenCenterX + wheelRadius * math.cos(math.rad(itemPos-90)) - 32
        local itemY = wheelY + wheelRadius * math.sin(math.rad(itemPos-90)) - 32
        
        getImage(itemArtFilePath):draw(itemX, itemY)

        -- draw menu item names
        local textWidth, textHeight = gfx.getTextSize(menuItemNames[i], fonts.orbeatsSans)
        local textX = screenCenterX + (wheelRadius-64) * math.cos(math.rad(itemPos-90)) - textWidth/2
        local textY = wheelY + (wheelRadius-64) * math.sin(math.rad(itemPos-90)) - textHeight/2
        local padding = 3
        if textWidth > 100 then
            local textWidth, textHeight = gfx.getTextSize(menuItemNames[i], fonts.orbeatsSmall)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(textX-padding, textY-padding, textWidth+padding*2, textHeight+padding*2, 2)
            gfx.drawText(menuItemNames[i], textX, textY, fonts.orbeatsSmall)
        else
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(textX-padding, textY-padding, textWidth+padding*2, textHeight+padding*2, 2)
            gfx.drawText(menuItemNames[i], textX, textY, fonts.orbeatsSans)
        end
    end

    -- draw the pointer
    local pointerY = wheelYTimer.value-(wheelRadiusTimer.value*1.35)
    pointerSprite:draw(screenCenterX-7, pointerY) 

    
    -- draw the input prompts
    local inputX = inputXTimer.value

    if drawInputPrompts then
        local padding = 3
        local roundedness = 3
        local inputY = 3
        -- draw the left prompts
        -- draw the back prompt
        local inputTextWidth, inputTextHeight = gfx.getTextSize(inputText.back, fonts.orbeatsSans)
        local inputXScaled = (inputX-1)*(inputTextWidth+padding*2)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(inputXScaled, inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(inputXScaled, inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
        gfx.drawText(inputText.back, inputXScaled+padding, inputY+padding, fonts.orbeatsSans)
        -- draw the left direction prompt
        inputTextWidth, inputTextHeight = gfx.getTextSize(inputText.left, fonts.orbeatsSans)
        inputXScaled = (inputX-1)*(inputTextWidth+padding*2)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(inputXScaled, inputTextHeight+padding*2+inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(inputXScaled, inputTextHeight+padding*2+inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
        gfx.drawText(inputText.left, inputXScaled+padding, inputY+inputTextHeight+padding*3, fonts.orbeatsSans)


        -- draw the right prompts
        -- draw the confirm prompt
        inputTextWidth, inputTextHeight = gfx.getTextSize(inputText.confirm, fonts.orbeatsSans)
        inputXScaled = screenWidth-inputX*(inputTextWidth+padding*2)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(inputXScaled, inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(inputXScaled, inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
        gfx.drawText(inputText.confirm, inputXScaled+padding, inputY+padding, fonts.orbeatsSans)
        -- draw the right direction prompt
        inputTextWidth, inputTextHeight = gfx.getTextSize(inputText.right, fonts.orbeatsSans)
        inputXScaled = screenWidth-inputX*(inputTextWidth+padding*2)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(inputXScaled, inputTextHeight+padding*2+inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(inputXScaled, inputTextHeight+padding*2+inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
        gfx.drawText(inputText.right, inputXScaled+padding, inputY+inputTextHeight+padding*3, fonts.orbeatsSans)
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