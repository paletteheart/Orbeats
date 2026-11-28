
-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics

local floor <const> = math.floor
local abs <const> = math.abs
local sin <const> = math.sin
local cos <const> = math.cos
local rad <const> = math.rad


--#region Math and Numbers

local radians

--- Takes a circle and a number of degrees and returns
--- coordinates corrosponding to the point at `degrees`
--- around its circumference.
--- 
--- The rightmost side is 0°/360°, and degrees go clockwise.
---@param circleX number
---@param circleY number
---@param degrees number
---@param radius number
---@return number x
---@return number y
function pointFromCirclePosition(circleX, circleY, radius, degrees)
    radians = rad(degrees)
    return circleX + radius * cos(radians), circleY + radius * sin(radians)
end

--- Takes an ellipse and a number of degrees and returns
--- coordinates corrosponding to the point at `degrees`
--- around its circumference.
--- 
--- The rightmost side is 0°/360°, and degrees go clockwise.
---@param ellipseX number
---@param ellipseY number
---@param degrees number
---@param xRadius number
---@param yRadius number
---@return number x
---@return number y
function pointFromEllipsePosition(ellipseX, ellipseY, xRadius, yRadius, degrees)
    radians = rad(degrees)
    return ellipseX + xRadius * cos(radians), ellipseY + yRadius * sin(radians)
end

--- Used to snap any point to every other x/y.
--- 
--- This is useful for making sure that images
--- with dithering don't flicker.
---@param x number
---@param y number
---@return integer
---@return integer
function pointToTwos(x, y)
    return floor(x*0.5)*2, floor(y*0.5)*2
end

--#endregion

--#region Strings and Text

--#region Symbols and Strings
char = {}
char.A = "Ⓐ"
char.B = "Ⓑ"
char.a = "Ⓐ"
char.b = "Ⓑ"
char.left = "←"
char.up = "↑"
char.right = "→"
char.down = "↓"
char.dir = "✛"
char.menu = "⊙"
char.cw = "↻"
char.ccw = "↺"
char.div = "∘--∘"

inputText = {
    left = char.left.."/"..char.ccw,
    right = char.right.."/"..char.cw,
    confirm = "Confirm:"..char.up.."/"..char.A,
    back = "Back:"..char.down.."/"..char.B,
    select = "Select:"..char.left.."/"..char.right.."/"..char.A,
    save = "Save and Exit:"..char.B,
    scroll = "Scroll:"..char.down.."/"..char.cw.."/"..char.up.."/"..char.ccw
}
--#endregion

--#region Fonts and Font Families
fontFamilies = {}
fontFamilies.orbeatsSans = gfx.font.newFamily({
    [gfx.font.kVariantNormal] = "fonts/Orbeats Sans"
})
fontFamilies.orbeatsSmall = gfx.font.newFamily({
    [gfx.font.kVariantNormal] = "fonts/Orbeats Small"
})
fontFamilies.odinRounded = gfx.font.newFamily({
    [gfx.font.kVariantNormal] = "fonts/Odin Rounded PD"
})
fontFamilies.carbonNumbers = gfx.font.newFamily({
    [gfx.font.kVariantNormal] = "fonts/Carbon Numbers"
})

fonts = {}
fonts.orbeatsSans = gfx.font.new("fonts/Orbeats Sans")
fonts.orbeatsSmall = gfx.font.new("fonts/Orbeats Small")
fonts.odinRounded = gfx.font.new("fonts/Odin Rounded PD")
fonts.carbonNumbers = gfx.font.new("fonts/Carbon Numbers")
--#endregion

function commaFormat(number)
    return string.format("%d", number):reverse():gsub( "(%d%d%d)" , "%1," ):reverse():gsub("^,","")
end

--#endregion

--#region Images and Drawing

notePatterns = {
    {0x99, 0x66, 0x66, 0x99, 0x99, 0x66, 0x66, 0x99}, -- checker big
    {0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA}, -- checker
    {0xD2, 0x5A, 0x4B, 0x69, 0x2D, 0xA5, 0xB4, 0x96}, -- diagonal
    {0x83, 0x7C, 0x45, 0x55, 0x45, 0x7C, 0x83, 0xBB}, -- squares and rectangles
    {0x5A, 0xA5, 0x5A, 0xA5, 0xA5, 0x5A, 0xA5, 0x5A}, -- circles
    {0x77, 0x11, 0xDD, 0x44, 0x77, 0x11, 0xDD, 0x44}, -- zigzags
    {0xF3, 0xF3, 0x30, 0x30, 0x3F, 0x3F, 0x3, 0x3}, -- big zigzags
    {0xA6, 0x59, 0x65, 0x9A, 0x6A, 0x95, 0x56, 0xA9} -- sharp zigzags
}

bgImage = gfx.image.new("sprites/stars2")
pointerImage = gfx.image.new("sprites/pointer")

animationTime = 300

function drawTextCentered(text, x, y, font)
    -- draws text centered both horizontally and vertically to the point given
    local textWidth, textHeight = gfx.getTextSize(text, font)
    gfx.setFontFamily(font)
    gfx.drawTextAligned(text, x, y-textHeight*0.5, kTextAlignment.center)
end

--#endregion

--#region Audio

--#region SFX
sfx = {}
sfx.low = pd.sound.sampleplayer.new("sfx/low")
sfx.mid = pd.sound.sampleplayer.new("sfx/mid")
sfx.high = pd.sound.sampleplayer.new("sfx/high")
sfx.play = pd.sound.sampleplayer.new("sfx/play")
sfx.click = pd.sound.sampleplayer.new("sfx/click")
sfx.switch = pd.sound.sampleplayer.new("sfx/switch")
sfx.tap = pd.sound.sampleplayer.new("sfx/tap")
sfx.jingle = pd.sound.sampleplayer.new("sfx/jingle")
-- sfx.combo_break = pd.sound.sampleplayer.new("sfx/combo_break")
local function getListOfHitSfx()
    local sfxFiles = pd.file.listFiles("/sfx/hit/")
    if sfxFiles == nil then sfxFiles = {} end

    for i=#sfxFiles,1,-1 do
        if sfxFiles[i]:sub(-4) ~= '.pda' then
            tableRemove(sfxFiles, i)
        else
            sfxFiles[i] = sfxFiles[i]:sub(1, -5)
            print(sfxFiles[i])
        end
    end

    local hitSfx = {}
    for i=1,#sfxFiles do
        hitSfx[i] = pd.sound.sampleplayer.new("sfx/hit/"..sfxFiles[i])
    end

    return hitSfx
end
sfx.hit = getListOfHitSfx()
--#endregion

bgmIntro = pd.sound.fileplayer.new("bgm/intro")
menuBgm = pd.sound.fileplayer.new("bgm/we are all listening")

---@return boolean
function isMenuMusicPlaying()
    return bgmIntro:isPlaying() or menuBgm:isPlaying()
end

function playMenuMusic()
    if isMenuMusicPlaying() then return end

    bgmIntro:play(1)
    bgmIntro:setFinishCallback(function()
        menuBgm:setOffset(6.741)
        menuBgm:play(0)
        menuBgm:setVolume(bgmIntro:getVolume())
    end)
    bgmIntro:setVolume(1)
end

function stopMenuMusic()
    if not isMenuMusicPlaying() then return end
    bgmIntro:setFinishCallback(function ()
        return
    end)
    bgmIntro:stop()
    menuBgm:stop()
end

function setMenuMusicVolume(volume, fade)
    if not isMenuMusicPlaying() then return end

    if fade == nil then fade = 0 end

    if bgmIntro:isPlaying() then
        bgmIntro:setVolume(volume, volume, fade)
    elseif menuBgm:isPlaying() then
        menuBgm:setVolume(volume, volume, fade)
    end
end

--#endregion

--#region Input Handling

crankPos = 0
crankChange = 0
upPressed = false
downPressed = false
leftPressed = false
rightPressed = false
aPressed = false
bPressed = false
hitPressed = false
flipPressed = false
buttonPressed = false
upHeld = false
downHeld = false
leftHeld = false
rightHeld = false
aHeld = false
bHeld = false
buttonHeld = false
buttonReleased = false

function updateInputs()
    -- update crank position
    crankPos = pd.getCrankPosition()
    crankChange = pd.getCrankChange()
    stats.crankTurns += abs(crankChange)/360
    -- update button inputs
    upPressed = pd.buttonJustPressed(pd.kButtonUp)
    downPressed = pd.buttonJustPressed(pd.kButtonDown)
    leftPressed = pd.buttonJustPressed(pd.kButtonLeft)
    rightPressed = pd.buttonJustPressed(pd.kButtonRight)
    aPressed = pd.buttonJustPressed(pd.kButtonA)
    bPressed = pd.buttonJustPressed(pd.kButtonB)

    hitPressed = downPressed or bPressed or rightPressed
    flipPressed = upPressed or aPressed or leftPressed
    buttonPressed = hitPressed or flipPressed

    upHeld = pd.buttonIsPressed(pd.kButtonUp)
    downHeld = pd.buttonIsPressed(pd.kButtonDown)
    leftHeld = pd.buttonIsPressed(pd.kButtonLeft)
    rightHeld = pd.buttonIsPressed(pd.kButtonRight)
    aHeld = pd.buttonIsPressed(pd.kButtonA)
    bHeld = pd.buttonIsPressed(pd.kButtonB)

    buttonHeld = downHeld or bHeld or upHeld or aHeld or leftHeld or rightHeld

    buttonReleased = pd.buttonJustReleased(pd.kButtonUp) or
                     pd.buttonJustReleased(pd.kButtonDown) or
                     pd.buttonJustReleased(pd.kButtonLeft) or
                     pd.buttonJustReleased(pd.kButtonRight) or
                     pd.buttonJustReleased(pd.kButtonA) or
                     pd.buttonJustReleased(pd.kButtonB)
end

--#endregion

--#region Record Handling

stats = pd.datastore.read("stats")
if stats == nil then
    stats = {}
end

--- Sets any table-bound statistic to the supplied value if not already set.
--- 
--- Value defaults to 0.
--- Table defaults to `stats`.
---@param stat string
---@param value? any
---@param table? table
---@return any
function initStat(stat, value, table)
    if value == nil then value = 0 end
    if table == nil then table = stats end
    if table[stat] == nil then
        table[stat] = value
        return value
    else
        return table[stat]
    end
end

--- Increments a numeric table-bound statistic by the supplied value.
--- If not already defined, the stat is defined as the value.
--- 
--- Value defaults to 1.
--- Table defaults to `stats`.
---@param stat string
---@param value number
---@param table table
---@return nil
function incrementStat(stat, value, table)
    if value == nil then value = 1 end
    if table == nil then table = stats end
    if table[stat] ~= nil then
        table[stat] += value
    else
        table[stat] = value
    end
    return table[stat]
end

scores = pd.datastore.read("scores")
if scores == nil then
    scores = {}
end

---@param songName string
---@param difficulty string
---@return integer score
---@return integer combo
---@return string rank
---@return boolean fullCombo
---@return boolean allPerfect
function getMapRecords(songName, difficulty)

    if scores[songName] == nil then scores[songName] = {} end

    if scores[songName][difficulty] == nil then scores[songName][difficulty] = {} end

    local hiScore = initStat("score", 0, scores[songName][difficulty])
    local hiCombo = initStat("combo", 0, scores[songName][difficulty])
    local rating = initStat("rating", "-", scores[songName][difficulty])
    local fullCombo = initStat("fc", false, scores[songName][difficulty])
    local allPerfect = initStat("ap", false, scores[songName][difficulty])

    return hiScore, hiCombo, rating, fullCombo, allPerfect
end

--#endregion