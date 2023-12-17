
--import note classes
import "notes/note"
import "notes/flipnote"
import "notes/holdnote"

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
char.a = "Ⓐ"
char.b = "Ⓑ"
char.left = "←"
char.up = "↑"
char.right = "→"
char.down = "↓"
char.menu = "⊙"
char.cw = "↻"
char.ccw = "↺"

fonts = {}
fonts.orbeatsSans = gfx.font.newFamily({
    [gfx.font.kVariantNormal] = "fonts/Orbeats Sans"
})
fonts.orbeatsSmall = gfx.font.newFamily({
    [gfx.font.kVariantNormal] = "fonts/Orbeats Small"
})
fonts.odinRounded = gfx.font.newFamily({
    [gfx.font.kVariantNormal] = "fonts/Odin Rounded PD"
})

-- Define variables
-- System variables
toMenu = false
restart = false
tickSpeed = 30
p = ParticleCircle()
p:setColor(gfx.kColorBlack)
p:setMode(Particles.modes.DECAY)
p:setThickness(0, 2)
p:setDecay(0.25)
p:setSpeed(1, 4)
p:setSize(3, 8)

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
crankChange = pd.getCrankChange()

upPressed = pd.buttonJustPressed(pd.kButtonUp)
downPressed = pd.buttonJustPressed(pd.kButtonDown)
leftPressed = pd.buttonJustPressed(pd.kButtonLeft)
rightPressed = pd.buttonJustPressed(pd.kButtonRight)
aPressed = pd.buttonJustPressed(pd.kButtonA)
bPressed = pd.buttonJustPressed(pd.kButtonB)

upHeld = pd.buttonIsPressed(pd.kButtonUp)
downHeld = pd.buttonIsPressed(pd.kButtonDown)
leftHeld = pd.buttonIsPressed(pd.kButtonLeft)
rightHeld = pd.buttonIsPressed(pd.kButtonRight)
aHeld = pd.buttonIsPressed(pd.kButtonA)
bHeld = pd.buttonIsPressed(pd.kButtonB)

-- Song variables
local songTable = json.decodeFile(pd.file.open("songs/Orubooru/Easy.json"))
local songBpm = 130
perfectHits = 0
hitNotes = 0
missedNotes = 0
local delta = -(tickSpeed*3)
local fadeOut = 1
local fadeIn = 0
local beatOffset = 0 -- a value to slightly offset the beat until it looks like it's perfectly on beat
restartTable = {}
restartTable.tablePath = "songs/Orubooru/Easy.json"
restartTable.bpm = songBpm
restartTable.beatOffset = beatOffset
restartTable.musicFilePath = "songs/Orubooru/Orubooru"

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

-- Note variables   
noteInstances = {}
local missedNoteRadius = 300 -- the radius where notes get deleted
local hitForgiveness = 25 -- the distance from the orbit radius from which you can still hit notes
local maxNoteScore = 100 --the max score you can get from a note
local perfectDistance = 4 -- the distance from the center of a note or from the exact orbit radius where you can still get a perfect note

-- Effects variables
local invertedScreen = false
local textInstances = {}
local oldOrbitCenterX = orbitCenterX -- used for animating orbit movement
local oldOrbitCenterY = orbitCenterY -- used for animating orbit movement
local lastMovementBeatX = 0 -- used for animating the orbit movement
local lastMovementBeatY = 0 -- used for animating the orbit movement



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
            if (noteData.newRadius >= orbitRadius-hitForgiveness and noteData.newRadius < orbitRadius) or ((noteData.oldRadius < orbitRadius or noteData.newRadius <= orbitRadius+hitForgiveness) and  noteData.newRadius >= orbitRadius) then
                local noteAngles = note:getNoteAngles()
                -- check if the player position is within the note
                if (playerPos > noteAngles.startAngle and playerPos < noteAngles.endAngle) or (playerPos+360 > noteAngles.startAngle and playerPos+360 < noteAngles.endAngle) or (playerPos-360 > noteAngles.startAngle and playerPos-360 < noteAngles.endAngle) then
                    if downPressed or bPressed then
                        --note is hit
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
                        -- create particles
                        p:moveTo(playerX, playerY)
                        p:setSpread(math.floor(playerPos-90), math.ceil(playerPos+90))
                        p:add(10)
                    end
                end
            end
        elseif noteData.noteType == "holdnote" then
            if (noteData.oldRadius < orbitRadius or noteData.newRadius <= orbitRadius+hitForgiveness) and noteData.newRadius >= orbitRadius then
                local noteAngles = note:getNoteAngles()
                -- check if the player position is within the note
                if (playerPos > noteAngles.startAngle and playerPos < noteAngles.endAngle) or (playerPos+360 > noteAngles.startAngle and playerPos+360 < noteAngles.endAngle) or (playerPos-360 > noteAngles.startAngle and playerPos-360 < noteAngles.endAngle) then
                    if downHeld or bHeld or upHeld or aHeld then
                        --note is hit
                        score += maxNoteScore
                        hitTextDisplay = hitText.perfect
                        perfectHits += 1
                        hitTextTimer = hitTextTime
                        --remove note
                        table.remove(noteInstances, i)
                        -- up the hit note score
                        hitNotes += 1
                        -- create particles
                        p:moveTo(playerX, playerY)
                        p:setSpread(math.floor(playerPos-90), math.ceil(playerPos+90))
                        p:add(3)
                    end
                end
            end
        elseif noteData.noteType == "flipnote" then
            -- check if the note is close enough to be hit
            if (noteData.newRadius >= orbitRadius-hitForgiveness and noteData.newRadius < orbitRadius) or ((noteData.oldRadius < orbitRadius or noteData.newRadius <= orbitRadius+hitForgiveness) and  noteData.newRadius >= orbitRadius) then
                local noteAngles = note:getNoteAngles()
                -- check if the player position is within the note
                if (playerPos > noteAngles.startAngle and playerPos < noteAngles.endAngle) or (playerPos+360 > noteAngles.startAngle and playerPos+360 < noteAngles.endAngle) or (playerPos-360 > noteAngles.startAngle and playerPos-360 < noteAngles.endAngle) then
                    if upPressed or aPressed then
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
                        -- create particles
                        p:moveTo(playerX, playerY)
                        p:setSpread(math.floor(playerPos-90), math.ceil(playerPos+90))
                        p:add(10)
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
        
        -- check if it's time to add that note
        -- check if the note is spawned before the music starts or not
        if nextNote.spawnBeat < 0 then
            -- fake the currenBeat with delta
            if nextNote.spawnBeat <= fakeCurrentBeat then
                -- Add note to instances
                if nextNote.type == "flipnote" then
                    table.insert(noteInstances, FlipNote(nextNote.spawnBeat, nextNote.hitBeat, nextNote.speed, nextNote.width, nextNote.position, nextNote.spin))
                elseif nextNote.type == "holdnote" then
                    table.insert(noteInstances, HoldNote(nextNote.spawnBeat, nextNote.hitBeat, nextNote.speed, nextNote.width, nextNote.position, nextNote.spin))
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
            elseif nextNote.type == "holdnote" then
                table.insert(noteInstances, HoldNote(nextNote.spawnBeat, nextNote.hitBeat, nextNote.speed, nextNote.width, nextNote.position, nextNote.spin))
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
        if fx.toggleInvert ~= nil then
            -- check if there's any more time the screen needs to be inverted
            if #fx.toggleInvert ~= 0 then
                -- get the next screen invert time
                local nextInversionTime = fx.toggleInvert[1]

                -- check if it's time for that inversion
                -- check if it's before the music
                if delta < 0 then
                    if nextInversionTime <= fakeCurrentBeat then
                        -- toggle the screen inversion
                        invertedScreen = not invertedScreen
                        -- remove this inversion from the list
                        table.remove(fx.toggleInvert, 1)
                    end
                else
                    if nextInversionTime <= currentBeat then
                        -- toggle the screen inversion
                        invertedScreen = not invertedScreen
                        -- remove this inversion from the list
                        table.remove(fx.toggleInvert, 1)
                    end
                end
            end
        end

        -- update the orbit position
        -- update the orbit x
        if fx.moveOrbitX ~= nil then
            -- check if there's any more updates to the orbit's position
            if #fx.moveOrbitX ~= 0 then
                -- get the next movement time
                local nextMovementBeat = fx.moveOrbitX[1].beat
                -- get the next movement location
                local nextOrbitCenterX = fx.moveOrbitX[1].x

                -- calculate the current orbit x based on the animation style
                if fx.moveOrbitX[1].animation == "none" or fx.moveOrbitX[1].animation == nil then
                    -- if there's no animation, check if it's time to teleport into place
                    if currentBeat >= nextMovementBeat then
                        orbitCenterX = nextOrbitCenterX
                        oldOrbitCenterX = orbitCenterX
                        lastMovementBeatX = nextMovementBeat
                        table.remove(fx.moveOrbitX, 1)
                    end
                else
                    -- if there is animation, get our current time in the animation
                    local t = (currentBeat - lastMovementBeatX) / (nextMovementBeat - lastMovementBeatX)
                    t = math.max(0, math.min(1, t))

                    if fx.moveOrbitX[1].animation == "linear" then
                        orbitCenterX = oldOrbitCenterX+(nextOrbitCenterX-oldOrbitCenterX)*t
                    elseif fx.moveOrbitX[1].animation == "ease-in" then
                        orbitCenterX = oldOrbitCenterX+(nextOrbitCenterX-oldOrbitCenterX)*t^fx.moveOrbitX[1].power
                    elseif fx.moveOrbitX[1].animation == "ease-out" then
                        orbitCenterX = oldOrbitCenterX+(nextOrbitCenterX-oldOrbitCenterX)*t^(1/fx.moveOrbitX[1].power)
                    end
                    -- set the old orbit x to the current one if we've reached the destination
                    if currentBeat >= nextMovementBeat then
                        oldOrbitCenterX = orbitCenterX
                        lastMovementBeatX = nextMovementBeat
                        table.remove(fx.moveOrbitX, 1)
                    end
                end
            end
        else
            orbitCenterX = screenCenterX
        end
        -- update the orbit y
        if fx.moveOrbitY ~= nil then
            -- check if there's any more updates to the orbit's position
            if #fx.moveOrbitY ~= 0 then
                -- get the next movement time
                local nextMovementBeat = fx.moveOrbitY[1].beat
                -- get the next movement location
                local nextOrbitCenterY = fx.moveOrbitY[1].y

                -- calculate the current orbit x based on the animation style
                if fx.moveOrbitY[1].animation == "none" or fx.moveOrbitY[1].animation == nil then
                    -- if there's no animation, check if it's time to teleport into place
                    if currentBeat >= nextMovementBeat then
                        orbitCenterY = nextOrbitCenterY
                        oldOrbitCenterY = orbitCenterY
                        lastMovementBeatY = nextMovementBeat
                        table.remove(fx.moveOrbitY, 1)
                    end
                else
                    -- if there is animation, get our current time in the animation
                    local t = (currentBeat - lastMovementBeatY) / (nextMovementBeat - lastMovementBeatY)
                    t = math.max(0, math.min(1, t))

                    if fx.moveOrbitY[1].animation == "linear" then
                        orbitCenterY = oldOrbitCenterY+(nextOrbitCenterY-oldOrbitCenterY)*t
                    elseif fx.moveOrbitY[1].animation == "ease-in" then
                        orbitCenterY = oldOrbitCenterY+(nextOrbitCenterY-oldOrbitCenterY)*t^fx.moveOrbitY[1].power
                    elseif fx.moveOrbitY[1].animation == "ease-out" then
                        orbitCenterY = oldOrbitCenterY+(nextOrbitCenterY-oldOrbitCenterY)*t^(1/fx.moveOrbitY[1].power)
                    end
                    -- set the old orbit x to the current one if we've reached the destination
                    if currentBeat >= nextMovementBeat then
                        oldOrbitCenterY = orbitCenterY
                        lastMovementBeatY = nextMovementBeat
                        table.remove(fx.moveOrbitY, 1)
                    end
                end
            end
        else
            orbitCenterY = screenCenterY
        end

        -- update the text effects
        if fx.text ~= nil then
            if #fx.text ~= 0 then
                for i=#fx.text,1,-1 do
                    if fx.text[i].startBeat <= currentBeat then
                        table.insert(textInstances, fx.text[i])
                        table.remove(fx.text, i)
                    end
                end
            end
        end
        for i=#textInstances,1,-1 do
            if textInstances[i].endBeat <= currentBeat then
                table.remove(textInstances, i)
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

    -- update fade in
    if fadeIn < 1 then fadeIn += 0.1 end

    -- Update the pulse if it's on a beat
    -- If it's before the music is playing, fake the pulses
    if not music:isPlaying() then
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
    
    -- update effects
    updateEffects()

    -- update player x and y based on player position
    playerX = orbitCenterX + orbitRadius * math.cos(math.rad(playerPos-90))
    playerY = orbitCenterY + orbitRadius * math.sin(math.rad(playerPos-90))

    --flip player if up is hit
    if upPressed or aPressed then
        playerFlipped = not playerFlipped
        -- set the trail behind the cursor when you flip
        flipTrail = orbitRadius*2
        flipPos = playerPos
    else
        flipTrail = math.floor(flipTrail/1.4)
    end

	--update notes
	updateNotes()
    -- create new notes
    createNotes()


    -- check if they're restarting the song
    if restart then
        music:stop()
        setUpSong(restartTable.bpm, restartTable.beatOffset, restartTable.musicFilePath, restartTable.tablePath)
        restart = false
    end
    -- check if they are going back to the song select menu
    if toMenu then
        if fadeOut > 0 then
            fadeOut -= 0.1
        else
            music:stop()
            toMenu = false
            return "songSelect"
        end
    end
    -- check if the song is over and are going to the song end screen
    if songTable.songEnd <= currentBeat then
        if fadeOut > 0 then
            fadeOut -= 0.1
        else
            music:stop()
            return "songEndScreen"
        end
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
    -- gfx.setColor(gfx.kColorWhite)
	-- gfx.fillCircleAtPoint(orbitCenterX, orbitCenterY, orbitRadius-pulse)
    gfx.setColor(gfx.kColorBlack)
	gfx.setDitherPattern(0.75)
	gfx.setLineWidth(5)
	gfx.drawCircleAtPoint(orbitCenterX, orbitCenterY, orbitRadius-pulse)

    --draw the orbit pulse
    local pulseLength = 17
    gfx.setColor(gfx.kColorBlack)
    if music:isPlaying() then
        gfx.setDitherPattern(0.75+0.25*(currentBeat%1))
        gfx.setLineWidth(5*(1-currentBeat%1))
        gfx.drawCircleAtPoint(orbitCenterX, orbitCenterY, orbitRadius-pulseDepth-pulseLength*(currentBeat%1))
    else
        gfx.setDitherPattern(0.75+0.25*(fakeCurrentBeat%1))
        gfx.setLineWidth(5*(1-fakeCurrentBeat%1))
        gfx.drawCircleAtPoint(orbitCenterX, orbitCenterY, orbitRadius-pulseDepth-pulseLength*(fakeCurrentBeat%1))
    end

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

    --draw and update the particles
    gfx.setColor(gfx.kColorBlack) -- set the color to make pdParticles work
    p:update()

	--draw the player
    local downBulge = 0
    if downPressed or bPressed then
        downBulge = 2
    end
	gfx.setColor(gfx.kColorWhite)
	gfx.fillCircleAtPoint(playerX, playerY, playerRadius+downBulge)
	gfx.setColor(gfx.kColorBlack)
	gfx.setLineWidth(2)
	gfx.drawCircleAtPoint(playerX, playerY, playerRadius+downBulge)

    -- draw text effects
    for i=#textInstances,1,-1 do
        if textInstances.font == nil then
            gfx.drawText(textInstances[i].text, textInstances[i].x, textInstances[i].y, fonts.orbeatsSmall)
        else
            gfx.drawText(textInstances[i].text, textInstances[i].x, textInstances[i].y, fonts[textInstances.font])
        end
    end

    --invert the screen if necessary
    if invertedScreen then
        gfx.setColor(gfx.kColorXOR)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    end

    -- draw the fade out or in if fading out or in
    if fadeOut ~= 1 then
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(fadeOut)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    end
    if fadeIn ~= 1 then
        gfx.setColor(gfx.kColorWhite)
        gfx.setDitherPattern(fadeIn)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    end
end


function setUpSong(bpm, beatOffset, musicFilePath, tablePath)
    -- reset vars
    -- Note variables
    noteInstances = {}
    -- Song Variables
    score = 0
    perfectHits = 0
    hitNotes = 0
    missedNotes = 0
    delta = -(tickSpeed*3)
    fadeOut = 1
    fadeIn = 0
    -- Music Variables
    isPlaying = false
    lastBeat = 0
    -- Misc variables
    invertedScreen = false
    playerFlipped = false
    orbitCenterX = screenCenterX
    orbitCenterY = screenCenterY

    -- set song data vars
    songTable = json.decodeFile(pd.file.open(tablePath))
    songBpm = bpm
    beatOffset = beatOffset

    restartTable.bpm = bpm
    restartTable.beatOffset = beatOffset
    restartTable.musicFilePath = musicFilePath
    restartTable.tablePath = tablePath

    -- load the music file
    music:load(musicFilePath)
    music:setVolume(1)
end


function updateInputs() -- used to check if buttons were pressed during a dead frame and update crank position
    -- update crank position
    crankPos = pd.getCrankPosition()
    crankChange = pd.getCrankChange()
    -- update button inputs
    upPressed = pd.buttonJustPressed(pd.kButtonUp)
    downPressed = pd.buttonJustPressed(pd.kButtonDown)
    leftPressed = pd.buttonJustPressed(pd.kButtonLeft)
    rightPressed = pd.buttonJustPressed(pd.kButtonRight)
    aPressed = pd.buttonJustPressed(pd.kButtonA)
    bPressed = pd.buttonJustPressed(pd.kButtonB)

    upHeld = pd.buttonIsPressed(pd.kButtonUp)
    downHeld = pd.buttonIsPressed(pd.kButtonDown)
    leftHeld = pd.buttonIsPressed(pd.kButtonLeft)
    rightHeld = pd.buttonIsPressed(pd.kButtonRight)
    aHeld = pd.buttonIsPressed(pd.kButtonA)
    bHeld = pd.buttonIsPressed(pd.kButtonB)
end

