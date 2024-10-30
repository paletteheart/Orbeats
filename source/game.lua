
--import note classes
import "notes/note"
import "notes/flipnote"
import "notes/slidenote"

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics
local ease <const> = pd.easingFunctions

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
char.dir = "✛"
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
fonts.carbonNumbers = gfx.font.newFamily({
    [gfx.font.kVariantNormal] = "fonts/Carbon Numbers"
})

-- Define variables
-- System variables
toMenu = false
restart = false
p = ParticleCircle()
p:setColor(gfx.kColorBlack)
p:setMode(Particles.modes.DECAY)
p:setThickness(0, 2)
p:setDecay(0.25)
p:setSpeed(1, 4)
p:setSize(3, 8)

bgImageTable = gfx.imagetable.new("sprites/bg")
bgAnim = gfx.animation.loop.new(10, bgImageTable)

sfx = {}
sfx.hit = {}

local function getListOfHitSfx()
    local sfxFiles = pd.file.listFiles("/sfx/hit/")
    if sfxFiles == nil then sfxFiles = {} end

    for i=#sfxFiles,1,-1 do
        if sfxFiles[i]:sub(-4) ~= '.pda' then
            table.remove(sfxFiles, i)
        else
            sfxFiles[i] = sfxFiles[i]:sub(1, -5)
            print(sfxFiles[i])
        end
    end

    for i=1,#sfxFiles do
        sfx.hit[i] = pd.sound.sampleplayer.new("sfx/hit/"..sfxFiles[i])
    end
end

getListOfHitSfx()

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
local health = 100
local noteDamage = 20
failed = false

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
local songTable = {}
local songBpm = 130
perfectHits = 0
hitNotes = 0
missedNotes = 0
notesLeft = 0
local fadeOut = 1
local fadeIn = 0
local beatOffset = 0 -- a value to slightly offset the beat until it looks like it's perfectly on beat
restartTable = {}
restartTable.tablePath = ""
restartTable.bpm = songBpm
restartTable.bpmChanges = {}
restartTable.beatOffset = beatOffset
restartTable.musicFilePath = ""
songEnded = false
local bpmChanges = {}

-- Score display variables
score = 0
local hitTextTimer = 0
local hitTextTime = 15
local hitTextDisplay = ""
local hitTextX = screenCenterX
local hitTextY = screenCenterY
local hitText = {}
hitText.perfect = "Perfect!"
hitText.great = "Great"
hitText.good = "Good"
hitText.ok = "Ok"
hitText.miss = "Miss!"

-- Combo variables
local combo = 0
largestCombo = 0
local splashText = 0
local splashTimer = 0
local splashTime = 30

-- Music variables
music = pd.sound.fileplayer.new()
local musicTime = 0
local currentBeat = 0
local fakeCurrentBeat = 0
local lastBeat = 0 -- is only used for the pulses right now
local referenceTime = 0 -- used to calculate the current beat in music with changing bpm
local referenceBeat = 0 -- used to represent how many beats came before a bpm change
local startTime = pd.sound.getCurrentTime()

-- Note variables   
noteInstances = {}
local notePool = {}
local missedNoteRadius <const> = 300 -- the radius where notes get deleted
local hitForgiveness <const> = 25 -- the distance from the orbit radius from which you can still hit notes
local maxNoteScore <const> = 100 --the max score you can get from a note
local perfectDistance <const> = 12 -- the distance from the center of a note or from the exact orbit radius where you can still get a perfect note

-- Effects variables
local invertedScreen = false
local textInstances = {}
local textPool = {}
local oldOrbitCenterX = orbitCenterX -- used for animating orbit movement
local oldOrbitCenterY = orbitCenterY -- used for animating orbit movement
local lastMovementBeatX = 0 -- used for animating the orbit movement
local lastMovementBeatY = 0 -- used for animating the orbit movement



-- local functions

local function incrementCombo()
    combo += 1
    largestCombo = math.max(largestCombo, combo)

    if combo % 25 == 0 and combo > 0 then
        splashText = combo
        splashTimer = splashTime
    end
end

local function songOver()
    
end

local function killNote(noteIndex)
    table.insert(notePool, noteInstances[noteIndex])
    table.remove(noteInstances, noteIndex)
end

local function spawnNote(noteType, spawnBeat, hitBeat, speed, width, position, spin, duration)
    -- test if a note of this type is already in the pool
    local newNote
    for i=#notePool,1,-1 do
        -- if so, move it from the pool
        if notePool[i]:isa(noteType) then
            newNote = notePool[i]
            table.remove(notePool, i)
            -- redefine the pool note's attributes to fit the new note
            newNote:init(spawnBeat, hitBeat, speed, width, position, spin, duration)
            break
        end
    end

    -- if not, create a note
    if newNote == nil then
        if noteType == "FlipNote" then
            newNote = FlipNote(spawnBeat, hitBeat, speed, width, position, spin, duration)
        elseif noteType == "SlideNote" then
            newNote = SlideNote(spawnBeat, hitBeat, speed, width, position, spin, duration)
        else
            newNote = Note(spawnBeat, hitBeat, speed, width, position, spin, duration)
        end
    end

    -- add new note to noteInstances
    table.insert(noteInstances, newNote)
end

local function updateLongNote(note, noteData, noteInstance)
    local noteStartAngle, noteEndAngle = note:getNoteAngles()
    if (playerPos > noteStartAngle and playerPos < noteEndAngle) or (playerPos+360 > noteStartAngle and playerPos+360 < noteEndAngle) or (playerPos-360 > noteStartAngle and playerPos-360 < noteEndAngle) then
        if downHeld or bHeld or rightHeld or upHeld or leftHeld or aHeld then
            -- continue hitting note
            if settings.particles then
                p:moveTo(playerX, playerY)
                p:setSpread(math.floor(playerPos-90), math.ceil(playerPos+90))
                p:add(1)
            end
            if noteData.endRadius >= orbitRadius then
                killNote(noteInstance)
            end
        else
            -- check if you're within the window of forgiveness
            if (noteData.endRadius >= orbitRadius-hitForgiveness) then
                killNote(noteInstance)
            else
                -- lose points proportional to the percent of the note you missed
                local remainingNotePercent
                if fakeCurrentBeat < 0 then
                    remainingNotePercent = (noteData.endBeat-fakeCurrentBeat)/(noteData.endBeat-noteData.hitBeat)
                    score -= math.floor(maxNoteScore*remainingNotePercent)
                    note:finishHitting(fakeCurrentBeat)
                else
                    remainingNotePercent = (noteData.endBeat-currentBeat)/(noteData.endBeat-noteData.hitBeat)
                    score -= math.floor(maxNoteScore*remainingNotePercent)
                    note:finishHitting(currentBeat)
                end-- check if you're within the window of forgiveness
        if (noteData.endRadius >= orbitRadius-hitForgiveness) then
            killNote(noteInstance)
        else
            -- lose points proportional to the percent of the note you missed
            local remainingNotePercent
            if fakeCurrentBeat < 0 then
                remainingNotePercent = (noteData.endBeat-fakeCurrentBeat)/(noteData.endBeat-noteData.hitBeat)
                score -= math.floor(maxNoteScore*remainingNotePercent)
                note:finishHitting(fakeCurrentBeat)
            else
                remainingNotePercent = (noteData.endBeat-currentBeat)/(noteData.endBeat-noteData.hitBeat)
                score -= math.floor(maxNoteScore*remainingNotePercent)
                note:finishHitting(currentBeat)
            end
        end
            end
        end
    else
        -- check if you're within the window of forgiveness
        if (noteData.endRadius >= orbitRadius-hitForgiveness) then
            killNote(noteInstance)
        else
            -- lose points proportional to the percent of the note you missed
            local remainingNotePercent
            if fakeCurrentBeat < 0 then
                remainingNotePercent = (noteData.endBeat-fakeCurrentBeat)/(noteData.endBeat-noteData.hitBeat)
                score -= math.floor(maxNoteScore*remainingNotePercent)
                note:finishHitting(fakeCurrentBeat)
            else
                remainingNotePercent = (noteData.endBeat-currentBeat)/(noteData.endBeat-noteData.hitBeat)
                score -= math.floor(maxNoteScore*remainingNotePercent)
                note:finishHitting(currentBeat)
            end
        end
    end
end

local function updateNotes()
    for i = #noteInstances, 1, -1 do
		-- get the current note
		local note = noteInstances[i]
		-- update the current note with the current level speed and get it's current radius, old radius, and position
        local noteData
        -- if the music isn't playing, fake the beat
        if fakeCurrentBeat < 0 then
            noteData = note:update(fakeCurrentBeat, orbitRadius)
        else
            noteData = note:update(currentBeat, orbitRadius)
        end
		
        -- Check if note can be hit or is being hit
        if noteData.noteType == "note" then
            if noteData.hitting then
                updateLongNote(note, noteData, i)
            else
                if (noteData.newRadius >= orbitRadius-hitForgiveness and noteData.newRadius < orbitRadius) or ((noteData.oldRadius < orbitRadius or noteData.newRadius <= orbitRadius+hitForgiveness) and  noteData.newRadius >= orbitRadius) then
                    local noteStartAngle, noteEndAngle = note:getNoteAngles()
                    -- check if the player position is within the note
                    if (playerPos > noteStartAngle and playerPos < noteEndAngle) or (playerPos+360 > noteStartAngle and playerPos+360 < noteEndAngle) or (playerPos-360 > noteStartAngle and playerPos-360 < noteEndAngle) then
                        if downPressed or bPressed or rightPressed then
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
                                -- this equation calculates the amount of points you get (between 100 and 50) proportional to the where the noteDistance is between the perfectDistance and the hitForgiveness
                                -- Probably don't mess with this equation
                                local hitScore = math.floor(maxNoteScore/(1+((noteDistance-perfectDistance)/(hitForgiveness-perfectDistance))))
                                score += hitScore
                                if hitScore < 65 then
                                    hitTextDisplay = hitText.ok.." "..hitScore
                                elseif hitScore < 75 then
                                    hitTextDisplay = hitText.good.." "..hitScore
                                else
                                    hitTextDisplay = hitText.great.." "..hitScore
                                end
                            end
                            hitTextTimer = hitTextTime
                            hitTextX = orbitCenterX + 20 * math.cos(math.rad(noteData.position+90))
                            hitTextY = orbitCenterY + 20 * math.sin(math.rad(noteData.position+90))
                            --remove note if a short note, begin hitting if a long note
                            if noteData.endRadius == noteData.newRadius then
                                killNote(i)
                            else
                                note:beginHitting(orbitRadius)
                            end
                            -- up the hit note score and combo counter
                            hitNotes += 1
                            incrementCombo()
                            -- up your health
                            health += noteDamage/2
                            -- create particles
                            if settings.particles then
                                p:moveTo(playerX, playerY)
                                p:setSpread(math.floor(playerPos-90), math.ceil(playerPos+90))
                                p:add(10)
                            end
                            -- play sfx
                            if settings.toggleSfx then
                                sfx.hit[settings.sfx]:play()
                            end
                        end
                    end
                end
            end
            
        elseif noteData.noteType == "slidenote" then
            if noteData.hitting then
                updateLongNote(note, noteData, i)
            else
                if (noteData.oldRadius < orbitRadius or noteData.newRadius <= orbitRadius+hitForgiveness) and noteData.newRadius >= orbitRadius then
                    local noteStartAngle, noteEndAngle = note:getNoteAngles()
                    -- check if the player position is within the note
                    if (playerPos > noteStartAngle and playerPos < noteEndAngle) or (playerPos+360 > noteStartAngle and playerPos+360 < noteEndAngle) or (playerPos-360 > noteStartAngle and playerPos-360 < noteEndAngle) then
                        if downHeld or bHeld or upHeld or aHeld or leftHeld or rightHeld then
                            --note is hit
                            score += maxNoteScore
                            hitTextDisplay = hitText.perfect
                            perfectHits += 1
                            hitTextTimer = hitTextTime
                            hitTextX = orbitCenterX + 20 * math.cos(math.rad(noteData.position+90))
                            hitTextY = orbitCenterY + 20 * math.sin(math.rad(noteData.position+90))
                            --remove note if a short note, begin hitting if a long note
                            if noteData.endRadius == noteData.newRadius then
                                killNote(i)
                            else
                                note:beginHitting(orbitRadius)
                            end
                            -- up the hit note score
                            hitNotes += 1
                            incrementCombo()
                            -- up your health
                            health += noteDamage/2
                            -- create particles
                            if settings.particles then
                                p:moveTo(playerX, playerY)
                                p:setSpread(math.floor(playerPos-90), math.ceil(playerPos+90))
                                p:add(3)
                            end
                            -- play sfx
                            if settings.toggleSfx then
                                sfx.hit[settings.sfx]:play()
                            end
                        end
                    end
                end
            end
        elseif noteData.noteType == "flipnote" then
            -- check if the note is close enough to be hit
            if (noteData.newRadius >= orbitRadius-hitForgiveness and noteData.newRadius < orbitRadius) or ((noteData.oldRadius < orbitRadius or noteData.newRadius <= orbitRadius+hitForgiveness) and  noteData.newRadius >= orbitRadius) then
                local noteStartAngle, noteEndAngle = note:getNoteAngles()
                -- check if the player position is within the note
                if (playerPos > noteStartAngle and playerPos < noteEndAngle) or (playerPos+360 > noteStartAngle and playerPos+360 < noteEndAngle) or (playerPos-360 > noteStartAngle and playerPos-360 < noteEndAngle) then
                    if upPressed or aPressed or leftPressed then
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
                            local hitScore = math.floor(maxNoteScore/(1+((noteDistance-perfectDistance)/(hitForgiveness-perfectDistance))))
                            score += hitScore
                            if hitScore < 65 then
                                hitTextDisplay = hitText.ok.." "..hitScore
                            elseif hitScore < 75 then
                                hitTextDisplay = hitText.good.." "..hitScore
                            else
                                hitTextDisplay = hitText.great.." "..hitScore
                            end
                        end
                        hitTextTimer = hitTextTime
                        hitTextX = orbitCenterX + 20 * math.cos(math.rad(noteData.position-90))
                        hitTextY = orbitCenterY + 20 * math.sin(math.rad(noteData.position-90))
                        --remove note
                        killNote(i)
                        -- up the hit note score
                        hitNotes += 1
                        incrementCombo()
                        -- up your health
                        health += noteDamage/2
                        -- create particles
                        if settings.particles then
                            p:moveTo(playerX, playerY)
                            p:setSpread(math.floor(playerPos-90), math.ceil(playerPos+90))
                            p:add(10)
                        end
                        -- play sfx
                        if settings.toggleSfx then
                            sfx.hit[settings.sfx]:play()
                        end
                    end
                end
            end
        end
        -- remove the current note if the radius is too large
        if noteData.endRadius > missedNoteRadius then
            killNote(i)
            -- up the missed note score
            missedNotes += 1
            combo = 0
            hitTextDisplay = hitText.miss
            hitTextTimer = hitTextTime
            hitTextX = orbitCenterX + 20 * math.cos(math.rad(noteData.position+90))
            hitTextY = orbitCenterY + 20 * math.sin(math.rad(noteData.position+90))
            -- lower health
            health -= noteDamage
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
            -- fake the currentBeat
            if nextNote.spawnBeat <= fakeCurrentBeat then
                -- Add note to instances
                spawnNote(nextNote.type, nextNote.spawnBeat, nextNote.hitBeat, nextNote.speed, nextNote.width, nextNote.position, nextNote.spin, nextNote.duration)
                -- Remove note from the table
                table.remove(songTable.notes, 1)
                -- Call again to check for any other notes that need spawning
                createNotes()
                -- print("Created at beat "..fakeCurrentBeat)
            end

        elseif nextNote.spawnBeat <= currentBeat then
            -- Add note to instances
            spawnNote(nextNote.type, nextNote.spawnBeat, nextNote.hitBeat, nextNote.speed, nextNote.width, nextNote.position, nextNote.spin, nextNote.duration)
            -- Remove note from the table
            table.remove(songTable.notes, 1)
            -- Call again to check for any other notes that need spawning
            createNotes()
            -- print("Created at beat "..currentBeat)
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
                if not music:isPlaying() then
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
                    -- check if the music is playing
                    if not music:isPlaying() then
                        if fakeCurrentBeat >= nextMovementBeat then
                            orbitCenterX = nextOrbitCenterX
                            oldOrbitCenterX = orbitCenterX
                            lastMovementBeatX = nextMovementBeat
                            table.remove(fx.moveOrbitX, 1)
                        end
                    else
                        if currentBeat >= nextMovementBeat then
                            orbitCenterX = nextOrbitCenterX
                            oldOrbitCenterX = orbitCenterX
                            lastMovementBeatX = nextMovementBeat
                            table.remove(fx.moveOrbitX, 1)
                        end
                    end
                else
                    -- if there is animation, get our current time in the animation
                    local t = (currentBeat - lastMovementBeatX) / (nextMovementBeat - lastMovementBeatX)
                    if not music:isPlaying() then
                        t = (fakeCurrentBeat - lastMovementBeatX) / (nextMovementBeat - lastMovementBeatX)
                    end
                    t = math.max(0, math.min(1, t))

                    if fx.moveOrbitX[1].animation == "ease-in" then
                        orbitCenterX = oldOrbitCenterX+(nextOrbitCenterX-oldOrbitCenterX)*t^fx.moveOrbitX[1].power
                    elseif fx.moveOrbitX[1].animation == "ease-out" then
                        orbitCenterX = oldOrbitCenterX+(nextOrbitCenterX-oldOrbitCenterX)*t^(1/fx.moveOrbitX[1].power)
                    else
                        orbitCenterX = ease[fx.moveOrbitX[1].animation](t, oldOrbitCenterX, nextOrbitCenterX-oldOrbitCenterX, 1, fx.moveOrbitX[1].power)
                    end
                    -- set the old orbit x to the current one if we've reached the destination
                    if not music:isPlaying() then
                        if fakeCurrentBeat >= nextMovementBeat then
                            oldOrbitCenterX = orbitCenterX
                            lastMovementBeatX = nextMovementBeat
                            table.remove(fx.moveOrbitX, 1)
                        end
                    else
                        if currentBeat >= nextMovementBeat then
                            oldOrbitCenterX = orbitCenterX
                            lastMovementBeatX = nextMovementBeat
                            table.remove(fx.moveOrbitX, 1)
                        end
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
                    if not music:isPlaying() then
                        if fakeCurrentBeat >= nextMovementBeat then
                            orbitCenterY = nextOrbitCenterY
                            oldOrbitCenterY = orbitCenterY
                            lastMovementBeatY = nextMovementBeat
                            table.remove(fx.moveOrbitY, 1)
                        end
                    else
                        if currentBeat >= nextMovementBeat then
                            orbitCenterY = nextOrbitCenterY
                            oldOrbitCenterY = orbitCenterY
                            lastMovementBeatY = nextMovementBeat
                            table.remove(fx.moveOrbitY, 1)
                        end
                    end
                else
                    -- if there is animation, get our current time in the animation
                    local t = (currentBeat - lastMovementBeatY) / (nextMovementBeat - lastMovementBeatY)
                    if not music:isPlaying() then
                        t = (fakeCurrentBeat - lastMovementBeatY) / (nextMovementBeat - lastMovementBeatY)
                    end
                    t = math.max(0, math.min(1, t))

                    if fx.moveOrbitY[1].animation == "ease-in" then
                        orbitCenterY = oldOrbitCenterY+(nextOrbitCenterY-oldOrbitCenterY)*t^fx.moveOrbitY[1].power
                    elseif fx.moveOrbitY[1].animation == "ease-out" then
                        orbitCenterY = oldOrbitCenterY+(nextOrbitCenterY-oldOrbitCenterY)*t^(1/fx.moveOrbitY[1].power)
                    else
                        orbitCenterY = ease[fx.moveOrbitY[1].animation](t, oldOrbitCenterY, nextOrbitCenterY-oldOrbitCenterY, 1, fx.moveOrbitY[1].power)
                    end
                    -- set the old orbit x to the current one if we've reached the destination
                    if not music:isPlaying() then
                        if fakeCurrentBeat >= nextMovementBeat then
                            oldOrbitCenterY = orbitCenterY
                            lastMovementBeatY = nextMovementBeat
                            table.remove(fx.moveOrbitY, 1)
                        end
                    else
                        if currentBeat >= nextMovementBeat then
                            oldOrbitCenterY = orbitCenterY
                            lastMovementBeatY = nextMovementBeat
                            table.remove(fx.moveOrbitY, 1)
                        end
                    end
                end
            end
        else
            orbitCenterY = screenCenterY
        end

        -- update the text effects
        if fx.text ~= nil then
            -- check if there's any more text effects
            if #fx.text ~= 0 then
                -- add all current text effects to the instance list
                for i=#fx.text,1,-1 do
                    -- check if the music is playing yet
                    if music:isPlaying() then
                        if fx.text[i].startBeat <= currentBeat then
                            table.insert(textInstances, fx.text[i])
                            table.remove(fx.text, i)
                        end
                    else
                        if fx.text[i].startBeat <= fakeCurrentBeat then
                            table.insert(textInstances, fx.text[i])
                            table.remove(fx.text, i)
                        end
                    end
                end
            end
        end
        -- cull all text instances past their expiration
        for i=#textInstances,1,-1 do
            if music:isPlaying() then
                if textInstances[i].endBeat <= currentBeat then
                    table.remove(textInstances, i)
                end
            else
                if textInstances[i].endBeat <= fakeCurrentBeat then
                    table.remove(textInstances, i)
                end
            end
        end

        -- update the bpm
        if bpmChanges ~= nil then
            -- check if there's any more bpm changes
            if #bpmChanges ~= 0 then
                local nextBpmChange = bpmChanges[1]
                -- check if it's time for the next bpm change
                if nextBpmChange.beat <= currentBeat then
                    songBpm = nextBpmChange.bpm
                    table.remove(bpmChanges, 1)
                    referenceTime = musicTime
                    referenceBeat = currentBeat
                end
            end
        end
    end
end

-- global functions

function updateSong()
    -- update the fake beat if the music isn't playing
    timeSinceStart = pd.sound.getCurrentTime()-startTime-3
    fakeCurrentBeat = (timeSinceStart)*(songBpm/60)-beatOffset

    -- update the audio timer variable
    musicTime = music:getOffset()
    -- update the current beat
    currentBeat = ((musicTime-referenceTime) / (60/songBpm))-beatOffset + referenceBeat

    -- clamp health
    health = math.min(100, math.max(0, health))
    if health == 0 then
        failed = true
    end

    -- update how many notes are left
    notesLeft = #songTable.notes + #noteInstances

    -- check if the song is over
    songEnded = songTable.songEnd <= currentBeat or songEnded or failed

    -- if seconds since level loaded is 0, begin playing song
    if (timeSinceStart >= 0 and not music:isPlaying()) or songEnded then
        music:play()
    end

    -- update fade in
    if fadeIn < 1 then fadeIn += 0.1 end

    -- Update the pulse if it's on a beat
    -- If it's before the music is playing, fake the pulses
    if not music:isPlaying() then
        if fakeCurrentBeat > lastBeat then
            pulse = pulseDepth
            lastBeat += 1
        else
            pulse = math.max(pulse-1, 0)
        end
    else
        -- music is playing now, do real pulses
        if currentBeat > lastBeat then
            pulse = pulseDepth
            lastBeat += 1
        else
            pulse = math.max(pulse-1, 0)
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
    if upPressed or aPressed or leftPressed then
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
        setUpSong(restartTable.bpm, restartTable.bpmChanges, restartTable.beatOffset, restartTable.musicFilePath, restartTable.tablePath)
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
    if songEnded then
        if fadeOut > 0 then
            fadeOut -= 0.1
            if music:isPlaying() then
                music:setVolume(music:getVolume()-0.1)
            end
        else
            music:stop()
            
            return "songEndScreen"
        end
    end
    return "song"
end


function drawSong()
    if missedNotes == 0 and combo >= #songTable.notes then
        gfx.setImageDrawMode(gfx.kDrawModeInverted)
        gfx.clear(gfx.kColorBlack)
    end
    
    --draw background
    if settings.drawBg then
        local bgW, bgH = bgAnim:image():getSize()
        local bgX = orbitCenterX-(bgW/2)
        local bgY = orbitCenterY-(bgH/2)
        bgAnim:draw(bgX, bgY)
    end


    --draw the point total
    gfx.drawText(score, 2, 2, fonts.orbeatsSans)

    --draw the combo counter
    if combo > 4 then
        gfx.drawText("Combo:"..combo, 2, 215, fonts.orbeatsSans)
    end

    --draw the health bar
    gfx.setColor(gfx.kColorBlack)
    gfx.setPattern({0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA})
    gfx.setLineWidth(5)
    gfx.drawLine(0, screenHeight-3, screenWidth*(health/100), screenHeight-3)

    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    --draw the orbit
    gfx.setColor(gfx.kColorWhite)
	gfx.fillCircleAtPoint(orbitCenterX, orbitCenterY, orbitRadius-pulse)
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
    if missedNotes == 0 and combo >= #songTable.notes then
        p:setColor(gfx.kColorWhite)
    else
        p:setColor(gfx.kColorBlack)
    end
    p:update()

	--draw the player
    local downBulge = 0
    if downPressed or bPressed or rightPressed then
        downBulge = 2
    end
	gfx.setColor(gfx.kColorWhite)
	gfx.fillCircleAtPoint(playerX, playerY, playerRadius+downBulge)
	gfx.setColor(gfx.kColorBlack)
	gfx.setLineWidth(2)
	gfx.drawCircleAtPoint(playerX, playerY, playerRadius+downBulge)

    --draw the hit text
    local hitTextWidth, hitTextHeight = gfx.getTextSize(hitTextDisplay, fonts.orbeatsSmall)
    if hitTextTimer > 0 then
        if hitTextTimer == hitTextTime then
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(hitTextX-hitTextWidth/2-1, hitTextY-hitTextHeight/2-3, hitTextWidth+2, hitTextHeight+2, 2)
            drawTextCentered(hitTextDisplay, hitTextX, hitTextY-2, fonts.orbeatsSmall)
        else
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRoundRect(hitTextX-hitTextWidth/2-1, hitTextY-hitTextHeight/2-1, hitTextWidth+2, hitTextHeight+2, 2)
            drawTextCentered(hitTextDisplay, hitTextX, hitTextY, fonts.orbeatsSmall)
        end
        hitTextTimer -= 1
    end

    -- draw text effects
    for i=#textInstances,1,-1 do
        if textInstances[i].font == nil then
            drawTextCentered(textInstances[i].text, textInstances[i].x, textInstances[i].y, fonts.orbeatsSmall)
        else
            drawTextCentered(textInstances[i].text, textInstances[i].x, textInstances[i].y, fonts[textInstances[i].font])
        end
    end

    -- draw the combo splash
    if settings.drawSplash then
        if splashTimer > 0 then
            if splashTimer < splashTime - 12 or splashTimer % 4 == 0 or splashTimer-1 % 4 == 0 then
                drawTextCentered(splashText, screenCenterX, screenCenterY, fonts.carbonNumbers)
            end
            splashTimer -= 1
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


function setUpSong(bpm, bpmChange, beatOffset, musicFilePath, tablePath)
    -- set song data vars
    songTable = json.decodeFile(pd.file.open(tablePath))
    songBpm = bpm
    bpmChanges = bpmChange
    beatOffset = beatOffset

    textInstances = {}


    restartTable.bpm = bpm
    restartTable.bpmChanges = bpmChanges
    restartTable.beatOffset = beatOffset
    restartTable.musicFilePath = musicFilePath
    restartTable.tablePath = tablePath

    -- load the music file
    music = pd.sound.fileplayer.new()
    music:load(musicFilePath)
    music:setVolume(1)
    music:setFinishCallback(songOver())

    -- reset vars
    -- Note variables
    noteInstances = {}
    -- Song Variables
    score = 0
    perfectHits = 0
    hitNotes = 0
    missedNotes = 0
    notesLeft = #songTable.notes
    combo = 0
    largestCombo = 0
    splashText = 0
    splashTimer = 0
    fadeOut = 1
    fadeIn = 0
    songEnded = false
    health = 100
    failed = false
    -- Music Variables
    lastBeat = -(songBpm/60)*3
    referenceTime = 0
    referenceBeat = 0
    startTime = pd.sound.getCurrentTime()
    -- Misc variables
    invertedScreen = false
    playerFlipped = false
    orbitCenterX = screenCenterX
    orbitCenterY = screenCenterY
    oldOrbitCenterX = orbitCenterX
    oldOrbitCenterY = orbitCenterY
    lastMovementBeatX = lastBeat
    lastMovementBeatY = lastMovementBeatX
end


function updateInputs() -- used to check if buttons were pressed during a dead frame and update crank position
    -- update crank position
    crankPos = pd.getCrankPosition()
    crankChange = pd.getCrankChange()
    stats.crankTurns += math.abs(crankChange)/360
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

function drawTextCentered(text, x, y, font)
    -- draws text centered both horizontally and vertically to the point given
    local textWidth, textHeight = gfx.getTextSize(text, font)
    gfx.setFontFamily(font)
    gfx.drawTextAligned(text, x, y-textHeight/2, kTextAlignment.center)
end