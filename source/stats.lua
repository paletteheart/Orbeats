
-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics

local tableInsert <const> = table.insert

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterY <const> = screenHeight / 2

local planetDither <const> = {0x80, 0x80, 0x7C, 0x2, 0x2, 0x2, 0x7C, 0x80}
local moon1Dither <const> = {0x7F, 0xA2, 0xDD, 0xBE, 0xBE, 0xBE, 0xDD, 0xA2}
local moon2Dither <const> = {0x83, 0x7C, 0x45, 0x55, 0x45, 0x7C, 0x83, 0xBB}
local starsBg <const> = gfx.image.new("sprites/stars")

-- Define variables
local statsText = {}

initStat("playTime")
initStat("crankTurns")

local toMenu = false
local init = true

local fadeOut = 1
local fadeIn = 0

local orbitDegrees = 0

local scroll = -11

local rankings = {
    "F",
    "D",
    "C",
    "B",
    "A",
    "S",
    "SS"
}

local days, hours, minutes, seconds
local playTimeText = {}
local timeFormat <const> = "%02d"
local function calculatePlayTime()
    days = math.floor(stats.playTime/86400)
    hours = math.floor((stats.playTime%86400)/3600)
    minutes = math.floor((stats.playTime%3600)/60)
    seconds = math.floor(stats.playTime%60)

    playTimeText = {}
    if days > 0 then
        tableInsert(playTimeText, timeFormat:format(days))
        tableInsert(playTimeText, ":")
        tableInsert(playTimeText, timeFormat:format(hours))
        tableInsert(playTimeText, ":")
    elseif hours > 0 then
        tableInsert(playTimeText, timeFormat:format(hours))
        tableInsert(playTimeText, ":")
    end
    tableInsert(playTimeText, timeFormat:format(minutes))
    tableInsert(playTimeText, ":")
    tableInsert(playTimeText, timeFormat:format(seconds))
    

    return table.concat(playTimeText)
end

local function readStats()
    stats = pd.datastore.read("stats")
    if stats == nil then
        stats = {}
    end

    statsText = {}

    initStat("lifetimeScore")
    tableInsert(statsText, "Lifetime Score: "..commaFormat(stats.lifetimeScore))

    -- Initialized on boot
    tableInsert(statsText, "Total Play Time: "..calculatePlayTime())

    initStat("hitNotes")
    tableInsert(statsText, commaFormat(stats.hitNotes).." Notes Hit")
    
    initStat("perfectHits")
    tableInsert(statsText, commaFormat(stats.perfectHits).." Perfect Hits")

    initStat("missedNotes")
    tableInsert(statsText, commaFormat(stats.missedNotes).." Missed Notes")

    initStat("levelsCompleted")
    tableInsert(statsText, commaFormat(stats.levelsCompleted).." Levels Finished")

    initStat("ranksReceived", {})
    tableInsert(statsText, "Ranks Received:")

    for i=1,#rankings do
        initStat(rankings[i], 0, stats.ranksReceived)
        tableInsert(statsText, "  "..rankings[i]..": "..commaFormat(stats.ranksReceived[rankings[i]]))
    end

    initStat("fullCombos")
    tableInsert(statsText, commaFormat(stats.fullCombos).." Full Combos")

    initStat("allPerfects")
    tableInsert(statsText, commaFormat(stats.allPerfects).." All Perfects")

    -- Initialized on boot
    tableInsert(statsText, "Crank Revolutions: "..commaFormat(round(stats.crankTurns)))


    pd.datastore.write(stats, "stats")
end


function updateStatsPage()

    -- initiate stats page
    if init then
        scroll = -11
        readStats()
        init = false
        playMenuMusic()
    end
    -- update the crank turns stat
    table.remove(statsText, #statsText)
    tableInsert(statsText, "Crank Revolutions: "..commaFormat(round(stats.crankTurns)))
    -- update the play time stat
    table.remove(statsText, 2)
    tableInsert(statsText, 2, "Total Play Time: "..calculatePlayTime())
    
    -- check inputs
    if downPressed or bPressed then
        toMenu = true
        sfx.low:play()
    end
    scroll += crankChange/45
    if scroll > #statsText-10 or scroll < 1 then
        scroll = closeDistance(scroll, math.min(#statsText-10, math.max(1, round(scroll))), 0.3)
    end
    if math.abs(crankChange) < 0.5 then orbitDegrees += 1 else orbitDegrees += crankChange end


    -- update fade in
    if fadeIn < 1 then
        fadeIn += 0.1
    end


    -- check if we're going back to the menu
    if toMenu then
        if fadeOut > 0 then
            fadeOut -= 0.1
        else
            toMenu = false
            fadeOut = 1
            scroll = -11
            init = true
            pd.datastore.write(stats, "stats")
            return "menu"
        end
    end

    return "stats"
end


local function drawPlanetAnim(x, y, degrees)
    local planetRadius = 50
    local moon1Radius = 20
    local moon2Radius = 10
    local orbitWidth = 100
    local orbitHeight = orbitWidth/3
    local orbitRotation = 30
    local moon2Speed = 0.65
    local moon2Mult = 1.25

    -- Calculate moon position
    local moon1X = x + orbitWidth * math.cos(math.rad(degrees)) * math.cos(math.rad(orbitRotation)) - orbitHeight * math.sin(math.rad(degrees)) * math.sin(math.rad(orbitRotation))
    local moon1Y = y + orbitWidth * math.cos(math.rad(degrees)) * math.sin(math.rad(orbitRotation)) + orbitHeight * math.sin(math.rad(degrees)) * math.cos(math.rad(orbitRotation))
    local moon2X = x + orbitWidth * moon2Mult * math.cos(math.rad(degrees*moon2Speed)) * math.cos(math.rad(orbitRotation)) - orbitHeight * moon2Mult * math.sin(math.rad(degrees*moon2Speed)) * math.sin(math.rad(orbitRotation))
    local moon2Y = y + orbitWidth * moon2Mult * math.cos(math.rad(degrees*moon2Speed)) * math.sin(math.rad(orbitRotation)) + orbitHeight * moon2Mult * math.sin(math.rad(degrees*moon2Speed)) * math.cos(math.rad(orbitRotation))

    -- -- draw the orbit behind the planet
    -- gfx.setLineWidth(2)
    -- gfx.setColor(gfx.kColorWhite)
    -- gfx.setDitherPattern(0.5)
    -- gfx.drawEllipseInRect(x-orbitRadius, y-orbitRadius/3, orbitRadius*2, orbitRadius*(2/3), -135, 135)

    -- Draw the second moon if behind the planet
    if math.abs((degrees*moon2Speed)%360) >= 180 then
        gfx.setPattern(moon2Dither)
        gfx.fillCircleAtPoint(moon2X, moon2Y, moon2Radius)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(3)
        gfx.drawCircleAtPoint(moon2X, moon2Y, moon2Radius)
    end

    -- Draw the first moon if behind the planet
    if math.abs(degrees%360) >= 180 then
        gfx.setPattern(moon1Dither)
        gfx.fillCircleAtPoint(moon1X, moon1Y, moon1Radius)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(3)
        gfx.drawCircleAtPoint(moon1X, moon1Y, moon1Radius)
    end

    -- Draw the planet
    gfx.setPattern(planetDither)
    gfx.fillCircleAtPoint(x, y, planetRadius)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(3)
    gfx.drawCircleAtPoint(x, y, planetRadius)

    -- -- draw the orbit in front of the planet
    -- gfx.setLineWidth(2)
    -- gfx.setColor(gfx.kColorWhite)
    -- gfx.setDitherPattern(0.5)
    -- gfx.drawEllipseInRect(x-orbitRadius, y-orbitRadius/3, orbitRadius*2, orbitRadius*(2/3), 135, 225)

    -- Draw the first moon if in front of the planet
    if math.abs(degrees%360) < 180 then
        gfx.setPattern(moon1Dither)
        gfx.fillCircleAtPoint(moon1X, moon1Y, moon1Radius)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(3)
        gfx.drawCircleAtPoint(moon1X, moon1Y, moon1Radius)
    end

    -- Draw the second moon if behind the planet
    if math.abs((degrees*moon2Speed)%360) < 180 then
        gfx.setPattern(moon2Dither)
        gfx.fillCircleAtPoint(moon2X, moon2Y, moon2Radius)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(3)
        gfx.drawCircleAtPoint(moon2X, moon2Y, moon2Radius)
    end
end

function drawStatsPage()

    -- draw the stars in the background
    starsBg:draw(200, 0)

    -- draw the stats text
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    local padding = 3
    for i=1,#statsText do
        local textHeight = 18
        local textY = (padding+textHeight)*(i-scroll)
        local textX = padding

        gfx.drawText(statsText[i], textX, textY, fontFamilies.orbeatsSans)
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- draw the planet animation
    drawPlanetAnim(300, screenCenterY, orbitDegrees)

    -- draw the input prompt
    local padding = 3
    local roundedness = 3
    local inputY = 3
    inputTextWidth, inputTextHeight = gfx.getTextSize(inputText.back, fontFamilies.orbeatsSans)
    inputX = screenWidth-(inputTextWidth+padding*2)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(inputX, inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawRoundRect(inputX, inputY, inputTextWidth+padding*2, inputTextHeight+padding*2, roundedness)
    gfx.drawText(inputText.back, inputX+padding, inputY+padding, fontFamilies.orbeatsSans)

    -- draw the fade in/out
    if fadeOut ~= 1 then
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(fadeOut)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    end
    if fadeIn ~= 1 then
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(fadeIn)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    end
end