
-- Define constants
local pd = playdate
local gfx = pd.graphics
local tmr = pd.timer
local ease = pd.easingFunctions

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterX <const> = screenWidth / 2
local screenCenterY <const> = screenHeight / 2

local tabIcons <const> = {
    visual = gfx.image.new("sprites/settingsTab1"),
    audio = gfx.image.new("sprites/settingsTab2"),
    system = gfx.image.new("sprites/settingsTab3"),
}

local settingDefaults <const> = {
    -- system settings
    songSorting = "bpm",
    favoritesFirst = true,
    drawFps = false,
    audioOffset = -0.07,

    -- visual settings
    particles = true,
    notePattern = 1,
    drawBg = true,
    drawSplash = true, -- combo splashes
    centerHitText = true,

    -- audio settings
    toggleSfx = true,
    sfx = 2,

    -- no option to change yet
    skipIntro = false, -- intro splash screens
    hideTips = false, -- hide the tips on the title screen

    drawTextFX = true,
    toggleInvertFX = true,
    toggleMoveFX = true, -- move orbit fx

    musicVolume = 1.0,
    sfxVolume = 1.0,

    -- mods
    oneButtonMode = false,
    noCrankMode = false,
    autoMode = false,
    damageMode = "normal", -- for normal/no fail/no misses
    speed = 1.0,

    -- misc
    tutorialPlayed = false,
    favorites = {},
}

-- define variables
settings = pd.datastore.read("settings")
if settings == nil then
    settings = {}
end
for key, value in pairs(settingDefaults) do
    if settings[key] == nil then
        settings[key] = settingDefaults[key]
    end
end
pd.datastore.write(settings, "settings")

local settingsText = {}
local textXTimer = tmr.new(0, -100, -100)

local settingsOrder = {
    "toggleSfx",
    "sfx",
    "particles",
    "notePattern",
    "drawBg",
    "drawSplash",
    "centerHitText",
    "drawFps",
    "oneButtonMode",
    "resetSave",
}
local settingsLabels = {
    on = "ON",
    off = "OFF",

    -- system settings
    drawFps = "Framerate Display",
    skipIntro = "Skip Splash Screens",
    hideTips = "Hide Title Screen Tips",
    resetSave = "Reset Save Data",

    -- visual settings
    particles = "Note Particles",
    notePattern = "Slide Note Pattern",
    drawBg = "Background FX",
    drawSplash = "Combo Splash",
    centerHitText = "Center Hit Info",
    drawTextFX = "Text FX",
    toggleInvertFX = "Screen Inversions",
    toggleMoveFX = "Move the Orbit",

    -- audio settings
    toggleSfx = "Toggle Hit SFX",
    sfx = "Hit Sound",
    musicVolume = "Music Volume",
    sfxVolume = "SFX Volume",


    oneButtonMode = "One Button Mode"

}

local toMenu = false
local fadeOut = 1
local init = true

local selection = 1
local selectionRounded = selection
local oldSelection = selection

local arcRadiusTimer = tmr.new(0, 0, 0)

local starsXTimer = tmr.new(0, screenWidth, screenWidth)
local starsBg = gfx.image.new("sprites/stars")

local inputXTimer = tmr.new(0, 0, 0)

local function readSettings()

    settingsText = {}
    
    for i=1,#settingsOrder do
        if type(settings[settingsOrder[i]]) == "boolean" then
            if settings[settingsOrder[i]] then
                table.insert(settingsText, settingsLabels[settingsOrder[i]]..settingsLabels.on)
            else
                table.insert(settingsText, settingsLabels[settingsOrder[i]]..settingsLabels.off)
            end
        elseif type(settings[settingsOrder[i]]) == "number" or type(settings[settingsOrder[i]]) == "string" then
            table.insert(settingsText, settingsLabels[settingsOrder[i]]..settings[settingsOrder[i]])
        else
            table.insert(settingsText, settingsLabels[settingsOrder[i]])
        end
    end
end

local function resetAnim()
    textXTimer = replaceTimer(textXTimer, 0, -100, -100)
    arcRadiusTimer = replaceTimer(arcRadiusTimer, 0, 0, 0)
    starsXTimer = replaceTimer(starsXTimer, 0, screenWidth, screenWidth)
    inputXTimer = replaceTimer(inputXTimer, 0, 0, 0)
end

local function startAnim()
    textXTimer = replaceTimer(textXTimer, animationTime, -100, 0, ease.outBack)
    arcRadiusTimer = replaceTimer(arcRadiusTimer, 3000, 0, screenWidth)
    arcRadiusTimer.repeats = true
    starsXTimer = replaceTimer(starsXTimer, 500, screenWidth*1.5, screenWidth/2, ease.outCubic)
    inputXTimer = replaceTimer(inputXTimer, animationTime, 0, 1, ease.outBack)
end

function updateSettings()

    -- init settings menu
    if init then
        settings = pd.datastore.read("settings")
        readSettings()
        startAnim()
        init = false
    end
    
    -- check inputs
    if bPressed then
        toMenu = true
        sfx.low:play()
    end
    if leftPressed or rightPressed or aPressed then
        if type(settings[settingsOrder[selectionRounded]]) == "boolean" then
            settings[settingsOrder[selectionRounded]] = not settings[settingsOrder[selectionRounded]]
            sfx.tap:play()
        elseif type(settings[settingsOrder[selectionRounded]]) == "number" then
            if settingsOrder[selectionRounded] == "notePattern" then
                if leftPressed then
                    settings[settingsOrder[selectionRounded]] -= 1
                else
                    settings[settingsOrder[selectionRounded]] += 1
                end
                if settings[settingsOrder[selectionRounded]] > #notePatterns then
                    settings[settingsOrder[selectionRounded]] = 1
                elseif settings[settingsOrder[selectionRounded]] < 1 then
                    settings[settingsOrder[selectionRounded]] = #notePatterns
                end
                sfx.tap:play()
            elseif settingsOrder[selectionRounded] == "sfx" then
                if leftPressed then
                    settings[settingsOrder[selectionRounded]] -= 1
                else
                    settings[settingsOrder[selectionRounded]] += 1
                end
                if settings[settingsOrder[selectionRounded]] > #sfx.hit then
                    settings[settingsOrder[selectionRounded]] = 1
                elseif settings[settingsOrder[selectionRounded]] < 1 then
                    settings[settingsOrder[selectionRounded]] = #sfx.hit
                end
                sfx.hit[settings[settingsOrder[selectionRounded]]]:play()
            end
        else
            if settingsOrder[selectionRounded] == "resetSave" then
                sfx.tap:play()
                toMenu = false
                fadeOut = 1
                init = true
                selection = 1
                resetAnim()
                pd.datastore.write(settings, "settings")
                return "reset"
            end
        end

        readSettings()
    end
    if downPressed then
        selection = selectionRounded+1
    end
    if upPressed then
        selection = selectionRounded-1
    end
    selection += crankChange/90
    selectionRounded = round(selection)
    if oldSelection ~= selectionRounded then
        sfx.click:play()
        oldSelection = selectionRounded
    end
    selection = math.min(#settingsText, math.max(selection, 1))

    -- check if we're going back to the menu
    if toMenu then
        if fadeOut > 0 then
            fadeOut -= 0.1
        else
            toMenu = false
            fadeOut = 1
            init = true
            selection = 1
            resetAnim()
            pd.datastore.write(settings, "settings")
            return "menu"
        end
    end

    return "settings"
end

function drawSettings()

    -- draw the stars background
    starsBg:draw(starsXTimer.value, 0)

    -- draw the example Slide note
    local arcRadius = arcRadiusTimer.value
    local arcX = starsXTimer.value+screenWidth/2
    local arcY = 180
    local arcStart = 265
    local arcEnd = 275
    gfx.setPattern(notePatterns[settings.notePattern])
    gfx.setLineWidth(5*(arcRadius/screenWidth))
    gfx.drawArc(arcX, arcY, arcRadius, arcStart, arcEnd)
    -- draw the planet the Slide note is coming from
    local planetRadius = 30
    gfx.fillCircleAtPoint(arcX, arcY, planetRadius)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(3)
    gfx.drawCircleAtPoint(arcX, arcY, planetRadius)

    -- draw the list of settings
    drawList(settingsText, selectionRounded, 3, 3+textXTimer.value, 200, 240, 3, fontFamilies.orbeatsSans, true, true)

    -- draw the game version number
    local versionWidth, versionHeight = gfx.getTextSize(pd.metadata.version, fontFamilies.orbeatsSmall)
    local versionPadding = 2
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    gfx.drawText(pd.metadata.version, versionPadding, screenHeight-versionHeight-versionPadding, fontFamilies.orbeatsSmall)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- draw the input prompts
    local padding = 3
    local roundedness = 3
    local inputY = 3
    inputX = inputXTimer.value
    -- draw the right prompts
    -- draw the scroll prompt
    inputTextWidth, inputTextHeight = gfx.getTextSize(inputText.scroll, fontFamilies.orbeatsSans)
    inputXScaled = screenWidth-inputX*(inputTextWidth+padding*2)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(inputXScaled, inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawRoundRect(inputXScaled, inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
    gfx.drawText(inputText.scroll, inputXScaled+padding, inputY+padding, fontFamilies.orbeatsSans)
    -- draw the select prompt
    inputTextWidth, inputTextHeight = gfx.getTextSize(inputText.select, fontFamilies.orbeatsSans)
    inputXScaled = screenWidth-inputX*(inputTextWidth+padding*2)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(inputXScaled, inputTextHeight+padding*2+inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawRoundRect(inputXScaled, inputTextHeight+padding*2+inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
    gfx.drawText(inputText.select, inputXScaled+padding, inputY+inputTextHeight+padding*3, fontFamilies.orbeatsSans)
    -- draw the save prompt
    inputTextWidth, inputTextHeight = gfx.getTextSize(inputText.save, fontFamilies.orbeatsSans)
    inputXScaled = screenWidth-inputX*(inputTextWidth+padding*2)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(inputXScaled, (inputTextHeight+padding*2)*2+inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawRoundRect(inputXScaled, (inputTextHeight+padding*2)*2+inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
    gfx.drawText(inputText.save, inputXScaled+padding, inputY+inputTextHeight*2+padding*5, fontFamilies.orbeatsSans)

    -- draw the fade out
    if fadeOut ~= 1 then
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(fadeOut)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    end
end


local function truncateString(string, width, font)
    local stringWidth = gfx.getTextSize(string, font)
    local newString = string

    while stringWidth > width do
        if newString:sub(-3) == "..." then
            newString = newString:sub(1, newString:len()-4).."..."
        else
            newString = newString:sub(1, newString:len()-1).."..."
        end
        stringWidth = gfx.getTextSize(newString, font)
    end

    return newString
end

function drawScrollingList(list, selectedItem, x, y, width, height, padding, font, fill, invert)
    local textHeight = font[playdate.graphics.font.kVariantNormal]:getHeight()
    local maxItems = math.floor(height/(textHeight+padding))
    for i=math.max(math.ceil(selectedItem-maxItems/2+1), 1),#list do
        local textY = y+(textHeight+padding)*(math.min(i, math.floor(i-selectedItem+maxItems/2))-1)+padding
        local textX = x+padding
        
        local truncatedText = truncateString(list[i], width, font)
        local selectBoxColor = gfx.kColorBlack
        local selectedTextColor = gfx.kDrawModeInverted
        local textColor = gfx.kDrawModeCopy
        if invert then
            selectBoxColor = gfx.kColorWhite
            selectedTextColor = gfx.kDrawModeCopy
            textColor = gfx.kDrawModeInverted
        end
        if selectedItem == i then
            local textWidth = gfx.getTextSize(truncatedText, font)
            gfx.setColor(selectBoxColor)
            if fill then
                gfx.fillRoundRect(textX-padding, textY-padding, textWidth+padding*2, textHeight+padding*2, 3)
                gfx.setImageDrawMode(selectedTextColor)
                gfx.drawText(truncatedText, textX, textY, font)
            else
                gfx.drawRoundRect(textX-padding, textY-padding, textWidth+padding*2, textHeight+padding*2, 3)
                gfx.setImageDrawMode(textColor)
                gfx.drawText(truncatedText, textX, textY, font)
            end
        else
            gfx.setImageDrawMode(textColor)
            gfx.drawText(truncatedText, textX, textY, font)
        end
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function drawList(list, selectedItem, x, y, width, height, padding, font, fill, invert)
    local textHeight = font[playdate.graphics.font.kVariantNormal]:getHeight()
    local maxItems = math.floor(height/(textHeight+padding))
    for i=1,math.min(#list, maxItems) do
        local textY = y+(textHeight+padding)*(i-1)+padding
        local textX = x+padding
        
        local truncatedText = truncateString(list[i], width, font)
        local selectBoxColor = gfx.kColorBlack
        local selectedTextColor = gfx.kDrawModeInverted
        local textColor = gfx.kDrawModeCopy
        if invert then
            selectBoxColor = gfx.kColorWhite
            selectedTextColor = gfx.kDrawModeCopy
            textColor = gfx.kDrawModeInverted
        end
        if selectedItem == i then
            local textWidth = gfx.getTextSize(truncatedText, font)
            gfx.setColor(selectBoxColor)
            if fill then
                gfx.fillRoundRect(textX-padding, textY-padding, textWidth+padding*2, textHeight+padding*2, 3)
                gfx.setImageDrawMode(selectedTextColor)
                gfx.drawText(truncatedText, textX, textY, font)
            else
                gfx.drawRoundRect(textX-padding, textY-padding, textWidth+padding*2, textHeight+padding*2, 3)
                gfx.setImageDrawMode(textColor)
                gfx.drawText(truncatedText, textX, textY, font)
            end
        else
            gfx.setImageDrawMode(textColor)
            gfx.drawText(truncatedText, textX, textY, font)
        end
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end