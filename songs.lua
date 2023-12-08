
import "game"

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterX <const> = screenWidth / 2
local screenCenterY <const> = screenHeight / 2

local songList <const> = json.decodeFile(pd.file.open("songlist.json"))

-- Define variables
scores = json.decodeFile(pd.file.open("scores.json"))

-- Song variables
currentSong = songList[1]
currentDifficulty = currentSong.difficulties[1]
songTable = {}

-- reset high scores variables
resetHiScores = false
local warningCurrentY = -45
warningTargetY = 5


function drawSongSelect()
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("Press up to start test song: "..currentSong.name..", "..currentDifficulty, 2, 2, fonts.orbeatsSans)

    -- Get the current selection's high score
    local currentHiScore
    local currentBestRank
    if scores[currentSong.name] ~= nil then
        if scores[currentSong.name][currentDifficulty] ~= nil then
            currentHiScore = scores[currentSong.name][currentDifficulty].score
            currentBestRank = scores[currentSong.name][currentDifficulty].rating
        else
            currentHiScore = 0
            currentBestRank = "-"
        end
    else
        currentHiScore = 0
        currentBestRank = "-"
    end
    gfx.drawText("Best Score: "..currentHiScore.." Best Rating: "..currentBestRank, 2, 22, fonts.orbeatsSans)

    -- check if we're on the reset high scores menu
    if resetHiScores then
        -- draw the reset high scores menu
        -- draw background
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(0.5)
        gfx.fillRect(0, 0, screenWidth, screenHeight)

        -- draw bubble
        gfx.setColor(gfx.kColorWhite)
        local resetBubbleWidth = 200
        local resetBubbleHeight = 120
        local resetBubbleX = screenCenterX-(resetBubbleWidth/2)
        local resetBubbleY = screenCenterY-(resetBubbleHeight/2)
        gfx.fillRoundRect(resetBubbleX, resetBubbleY, resetBubbleWidth, resetBubbleHeight, 3)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(1)
        gfx.drawRoundRect(resetBubbleX, resetBubbleY, resetBubbleWidth, resetBubbleHeight, 3)

        -- draw text
        if warningCurrentY ~= warningTargetY then
            local change = (warningTargetY - warningCurrentY)*0.3
            warningCurrentY += math.floor(change)
        end
        gfx.drawText("WARNING!", screenCenterX-(gfx.getTextSize("WARNING!", fonts.odinRounded)/2), warningCurrentY, fonts.odinRounded)
        local textX = screenCenterX-(gfx.getTextSize("THIS WILL RESET ALL\nYOUR SCORES!", fonts.orbeatsSans)/2)
        gfx.drawText("THIS WILL RESET ALL\nYOUR SCORES!", textX, resetBubbleY+11, fonts.orbeatsSans)
        gfx.drawText("Press "..char.up.." and "..char.A.." to\nconfirm.", textX, resetBubbleY+51, fonts.orbeatsSans)
        gfx.drawText("Press "..char.down.."/"..char.B.." to cancel.", textX, resetBubbleY+91, fonts.orbeatsSans)

    end
end


function updateSongSelect()
    -- update inputs
    crankPos = pd.getCrankPosition()

    -- check if we're in the reset high scores menu
    if not resetHiScores then
        if upPressed then

            -- test code to automatically start the first song
            local bpm = currentSong.bpm
            local musicFile = "songs/"..currentSong.name.."/"..currentSong.name
            songTable = json.decodeFile(pd.file.open("songs/"..currentSong.name.."/"..currentDifficulty..".json"))
            local beatOffset = currentSong.beatOffset
            setUpSong(bpm, beatOffset, musicFile, songTable)
            return "song"
        end
    
        
    else
        if upHeld and aHeld then
            pd.datastore.write({}, "scores")
            scores = json.decodeFile(pd.file.open("scores.json"))
            warningTargetY = -45
        elseif downPressed or bPressed then
            warningTargetY = -45
        end
        if warningTargetY == -45 and warningCurrentY == -45 then
            resetHiScores = false
        end
    end
    

    return "songSelect"
end

function closeDistance(currentVal, targetVal, speed)
    local newVal = currentVal
    if currentVal ~= targetVal then
        local change = (targetVal - currentVal)*speed
        newVal = currentVal+change
    end
    return newVal
end