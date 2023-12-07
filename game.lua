
--import note classes
import "notes/note"
import "notes/flipnote"

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterX <const> = screenWidth / 2
local screenCenterY <const> = screenHeight / 2

char = {}
char.A = "Ⓐ"
char.B = "Ⓑ"
char.left = "←"
char.up = "↑"
char.right = "→"
char.down = "↓"
char.menu = "⊙"
char.cw = "↻"
char.ccw = "↺"

-- Define variables
-- System variables
toMenu = false
tickSpeed = 30

-- Orbit variables
local orbitRadius = 110
local orbitCenterX = screenCenterX
local orbitCenterY = screenCenterY

local pulse = 0
local pulseDepth = 3

-- Player variables
local playerX = orbitCenterX + orbitRadius
local playerY = orbitCenterY
local playerPos = crankPos
local playerRadius = 8
local playerFlipped = false
local flipTrail = 0
local flipPos = 0

-- input variables
crankPos = pd.getCrankPosition()
upPressed = pd.buttonJustPressed(pd.kButtonUp)
downPressed = pd.buttonJustPressed(pd.kButtonDown)
leftPressed = pd.buttonJustPressed(pd.kButtonLeft)
rightPressed = pd.buttonJustPressed(pd.kButtonRight)
aPressed = pd.buttonJustPressed(pd.kButtonA)
bPressed = pd.buttonJustPressed(pd.kButtonB)

upHeld = pd.buttonIsPressed(pd.kButtonUp)
leftHeld = pd.buttonIsPressed(pd.kButtonLeft)
rightHeld = pd.buttonIsPressed(pd.kButtonRight)
aHeld = pd.buttonIsPressed(pd.kButtonA)

-- Song variables
local songTable = json.decodeFile(pd.file.open("songs/Orubooru/Easy.json"))
local songBpm = 130
perfectHits = 0
hitNotes = 0
missedNotes = 0
local delta = -(tickSpeed*3)

-- Score display variables
score = 0
local hitTextTimer = 0
local hitTextTime = 15
local hitTextDisplay = ""
local hitText = {}
hitText.perfect = "Perfect!"
hitText.miss = "Miss!"

-- Music variables
music = pd.sound.fileplayer.new()
local musicTime = 0
local currentBeat = 0
local fakeCurrentBeat = 0
local lastBeat = 0 -- is only used for the pulses right now
local beatOffset = 0 -- a value to slightly offset the beat until it looks like it's perfectly on beat

-- Note variables   
noteInstances = {}
local missedNoteRadius = 300 -- the radius where notes get deleted
local hitForgiveness = 25 -- the distance from the orbit radius from which you can still hit notes
local maxNoteScore = 100 --the max score you can get from a note
local perfectDistance = 4 -- the distance from the center of a note or from the exact orbit radius where you can still get a perfect note

-- Font variables
fonts = {}
fonts.orbeatsSans = gfx.font.newFamily({
    [playdate.graphics.font.kVariantNormal] = "fonts/Orbeats Sans"
   })
fonts.odinRounded = gfx.font.newFamily({
    [playdate.graphics.font.kVariantNormal] = "fonts/Odin Rounded PD"
   })

-- Misc variables
local invertedScreen = false



-- local functions

local function updateNotes()
    for i = #noteInstances, 1, -1 do
		-- get the current note
		local note = noteInstances[i]
		-- update the current note with the current level speed and get it's current radius, old radius, and position
        local noteData
        -- if the music isn't playing, fake the beat
        if delta < 0 then
            noteData = note:update(fakeCurrentBeat, orbitRadius)
        else
            noteData = note:update(currentBeat, orbitRadius)
        end
		
        -- Check if note can be hit
        if noteData.noteType == "note" then
            if (noteData.oldRadius < orbitRadius or noteData.newRadius <= orbitRadius+hitForgiveness) and noteData.newRadius >= orbitRadius then
                local noteAngles = note:getNoteAngles()
                -- check if the player position is within the note
                if (playerPos > noteAngles.startAngle and playerPos < noteAngles.endAngle) or (playerPos+360 > noteAngles.startAngle and playerPos+360 < noteAngles.endAngle) or (playerPos-360 > noteAngles.startAngle and playerPos-360 < noteAngles.endAngle) then
                    --note is hit
                    --figure out how many points you get
                    local noteHalfWidth = (noteAngles.endAngle - noteAngles.startAngle)/2
                    local notePos = noteAngles.startAngle + noteHalfWidth
                    local fromNoteCenter = 0
                    -- figure out the distance from the center of the note
                    if playerPos+360 > noteAngles.startAngle and playerPos+360 < noteAngles.endAngle then
                        fromNoteCenter = math.abs(playerPos+360-notePos)
                    elseif playerPos-360 > noteAngles.startAngle and playerPos-360 < noteAngles.endAngle then
                        fromNoteCenter = math.abs(playerPos-360-notePos)
                    else
                        fromNoteCenter = math.abs(playerPos-notePos)
                    end
                    -- if you hit it perfectly in the center, score the max points. Otherwise, you score less and less, down to the edges which score half max points.
                    if fromNoteCenter <= perfectDistance then
                        score += maxNoteScore
                        hitTextDisplay = hitText.perfect
                        perfectHits += 1
                    else
                        local hitScore = math.floor(maxNoteScore/(1+(fromNoteCenter/noteHalfWidth)))
                        score += hitScore
                        hitTextDisplay = tostring(hitScore)
                    end
                    hitTextTimer = hitTextTime
                    --remove note
                    table.remove(noteInstances, i)
                    -- up the hit note score
                    hitNotes += 1
                end
            end
        else
            -- check if the note is close enough to be hit
            if (noteData.newRadius >= orbitRadius-hitForgiveness and noteData.newRadius < orbitRadius) or ((noteData.oldRadius < orbitRadius or noteData.newRadius <= orbitRadius+hitForgiveness) and  noteData.newRadius >= orbitRadius) then
                local noteAngles = note:getNoteAngles()
                -- check if the player position is within the note
                if (playerPos > noteAngles.startAngle and playerPos < noteAngles.endAngle) or (playerPos+360 > noteAngles.startAngle and playerPos+360 < noteAngles.endAngle) or (playerPos-360 > noteAngles.startAngle and playerPos-360 < noteAngles.endAngle) then
                    if upPressed then
                        -- note is hit
                        --figure out how many points you get
                        local noteDistance = math.abs(orbitRadius-noteData.newRadius)
                        -- if you hit it perfectly as it reaches the orbit, score the max points. Otherwise, you score less and less, down to the furthest from the orbit
                        -- you can be, which scores half max points.
                        if noteDistance <= perfectDistance then
                            score += maxNoteScore
                            hitTextDisplay = hitText.perfect
                            perfectHits += 1
                        else 
                            local hitScore = math.floor(maxNoteScore/(1+(noteDistance/hitForgiveness)))
                            score += hitScore
                            hitTextDisplay = tostring(hitScore)
                        end
                        hitTextTimer = hitTextTime
                        --remove note
                        table.remove(noteInstances, i)
                        -- up the hit note score
                        hitNotes += 1
                    end
                end
            end
        end
        -- remove the current note if the radius is too large
        if noteData.newRadius > missedNoteRadius then
            table.remove(noteInstances, i)
            -- up the missed note score
            missedNotes += 1
            hitTextDisplay = hitText.miss
            hitTextTimer = hitTextTime
        end
	end
end


local function createNotes()
    -- check if there's any notes left
    if #songTable.notes > 0 then
        -- get next note
        local nextNote = songTable.notes[1]
        -- figure out how many frames there are until a note is supposed to be hit
        
        -- check if it's time to add that note
        -- check if the note is spawned before the music starts or not
        if nextNote.spawnBeat < 0 then
            -- fake the currenBeat with delta
            if nextNote.spawnBeat <= fakeCurrentBeat then
                -- Add note to instances
                if nextNote.type == "flipnote" then
                    table.insert(noteInstances, FlipNote(nextNote.spawnBeat, nextNote.hitBeat, nextNote.speed, nextNote.width, nextNote.position, nextNote.spin))
                else
                    table.insert(noteInstances, Note(nextNote.spawnBeat, nextNote.hitBeat, nextNote.speed, nextNote.width, nextNote.position, nextNote.spin))
                end
                -- Remove note from the table
                table.remove(songTable.notes, 1)

            end

        elseif nextNote.spawnBeat <= currentBeat then

            -- Add note to instances
            if nextNote.type == "flipnote" then
                table.insert(noteInstances, FlipNote(nextNote.spawnBeat, nextNote.hitBeat, nextNote.speed, nextNote.width, nextNote.position, nextNote.spin))
            else
                table.insert(noteInstances, Note(nextNote.spawnBeat, nextNote.hitBeat, nextNote.speed, nextNote.width, nextNote.position, nextNote.spin))
            end
            -- Remove note from the table
            table.remove(songTable.notes, 1)
        end
    end
end


local function updateEffects()
    -- update effects
    local fx = songTable.effects
    if fx ~= nil then
        -- update the screen inversion
        if fx.toggleinvert ~= nil then
            -- check if there's any more time the screen needs to be inverted
            if #fx.toggleinvert ~= 0 then
                -- get the next screen invert time
                local nextInversionTime = fx.toggleinvert[1]

                -- check if it's time for that inversion
                -- check if it's before the music
                if delta < 0 then
                    if nextInversionTime <= fakeCurrentBeat then
                        -- toggle the screen inversion
                        invertedScreen = not invertedScreen
                        -- remove this inversion from the list
                        table.remove(fx.toggleinvert, 1)
                    end
                else
                    if nextInversionTime <= currentBeat then
                        -- toggle the screen inversion
                        invertedScreen = not invertedScreen
                        -- remove this inversion from the list
                        table.remove(fx.toggleinvert, 1)
                    end
                end
            end
        end

    end
end

-- global functions

function updateSong()
    -- Update the delta
    delta += 1
    -- update the fake beat if the music isn't playing
    fakeCurrentBeat = delta / math.floor((tickSpeed*60)/songBpm)

    -- if delta is 0, begin playing song
    if delta >= 0 and not music:isPlaying() then
        music:play()
    end

    -- update the audio timer variable
    musicTime = music:getOffset()
    -- update the current beat
    currentBeat = (musicTime / (60/songBpm))-beatOffset

    -- Update the pulse if it's on a beat
    -- If it's before the music is playing, fake the pulses
    if delta < 0 then
        if delta % math.floor((tickSpeed*60)/songBpm) == 0 then
            pulse = pulseDepth
        else
            pulse = 0
        end
    else
        -- music is playing now, do real pulses
        if currentBeat > lastBeat then
            pulse = pulseDepth
            lastBeat += 1
        else
            pulse = 0
        end
    end

    -- update player position based on crank position
    if playerFlipped then
        playerPos = crankPos+180
        if playerPos > 360 then playerPos -= 360 end
    else
        playerPos = crankPos
    end

    -- update player x and y based on player position
    playerX = orbitCenterX + orbitRadius * math.cos(math.rad(playerPos-90))
    playerY = orbitCenterY + orbitRadius * math.sin(math.rad(playerPos-90))

    --flip player if up is hit
    if upPressed then
        playerFlipped = not playerFlipped
        -- set the trail behind the cursor when you flip
        flipTrail = orbitRadius*2
        flipPos = playerPos
    else
        flipTrail = math.floor(flipTrail/1.4)
    end

    -- update hit forgiveness
    hitForgiveness = 25*songSpd

	--update notes
	updateNotes()
    -- create new notes
    createNotes()
    -- update effects
    updateEffects()


    -- check if they are going back to the song select menu
    if toMenu then
        music:stop()
        toMenu = false
        return "songSelect"
    end
    -- check if the song is over and are going to the song end screen
    if songTable.songend <= currentBeat then
        music:stop()
        return "songEndScreen"
    end
    return "song"
end


function drawSong()
    --draw the point total
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText(score, 2, 2, fonts.orbeatsSans)

    --draw the hit text
    if hitTextTimer > 0 then
        if hitTextTimer == hitTextTime then
            gfx.drawText(hitTextDisplay, 2, 18, fonts.orbeatsSans)
        else
            gfx.drawText(hitTextDisplay, 2, 20, fonts.orbeatsSans)
        end
    end
    hitTextTimer -= 1

    --draw the orbit
	gfx.setDitherPattern(0.75)
	gfx.setLineWidth(5)
	gfx.drawCircleAtPoint(orbitCenterX, orbitCenterY, orbitRadius-pulse)

	--draw the notes
	for i = #noteInstances, 1, -1 do
		-- get the current note
		local note = noteInstances[i]
		-- update the current note with the current level speed and get it's current radius, old radius, and position
        note:draw(orbitCenterX, orbitCenterY, orbitRadius)
    end

    --draw the trail
    if flipTrail > 0 then
        gfx.setDitherPattern(0.5)
        -- draw a circle where you were flipped to
        local trailX = orbitCenterX + orbitRadius * math.cos(math.rad(flipPos-270))
        local trailY = orbitCenterY + orbitRadius * math.sin(math.rad(flipPos-270))
        local trailRadius = (flipTrail/(orbitRadius*2))*playerRadius
        gfx.fillCircleAtPoint(trailX, trailY, trailRadius)
        -- draw a triangle pointed where you flipped from
        local tangentStartX = trailX + trailRadius * math.cos(math.rad(flipPos+180))
        local tangentStartY = trailY + trailRadius * math.sin(math.rad(flipPos+180))
        local tangentEndX = trailX + trailRadius * math.cos(math.rad(flipPos))
        local tangentEndY = trailY + trailRadius * math.sin(math.rad(flipPos))
        local pointX = trailX - flipTrail * math.cos(math.rad(flipPos+90))
        local pointY = trailY - flipTrail * math.sin(math.rad(flipPos+90))
        gfx.fillTriangle(tangentStartX, tangentStartY, tangentEndX, tangentEndY, pointX, pointY)
    end

	--draw the player
	gfx.setColor(gfx.kColorWhite)
	gfx.fillCircleAtPoint(playerX, playerY, playerRadius)
	gfx.setColor(gfx.kColorBlack)
	gfx.setLineWidth(2)
	gfx.drawCircleAtPoint(playerX, playerY, playerRadius)

    --invert the screen if necessary
    if invertedScreen then
        gfx.setColor(gfx.kColorXOR)
        gfx.fillRect(0, 0, 400, 240)
    end
end


function setUpSong(bpm, beatOffset, musicFilePath, table)
    -- reset vars
    -- Note variables
    noteInstances = {}
    -- Song Variables
    songSpd = 1.1
    score = 0
    hitNotes = 0
    missedNotes = 0
    delta = -(tickSpeed*3)
    -- Music Variables
    isPlaying = false
    lastBeat = 0
    -- Misc variables
    invertedScreen = false
    playerFlipped = false

    -- set song data vars
    songTable = table
    songBpm = bpm
    beatOffset = beatOffset

    -- load the music file
    music:load(musicFilePath)
end


function updateInputs() -- used to check if buttons were pressed during a dead frame and update crank position
    -- update crank position
    crankPos = pd.getCrankPosition()
    -- update button inputs
    upPressed = pd.buttonJustPressed(pd.kButtonUp)
    downPressed = pd.buttonJustPressed(pd.kButtonDown)
    leftPressed = pd.buttonJustPressed(pd.kButtonLeft)
    rightPressed = pd.buttonJustPressed(pd.kButtonRight)
    aPressed = pd.buttonJustPressed(pd.kButtonA)
    bPressed = pd.buttonJustPressed(pd.kButtonB)

    upHeld = pd.buttonIsPressed(pd.kButtonUp)
    leftHeld = pd.buttonIsPressed(pd.kButtonLeft)
    rightHeld = pd.buttonIsPressed(pd.kButtonRight)
    aHeld = pd.buttonIsPressed(pd.kButtonA)
end



