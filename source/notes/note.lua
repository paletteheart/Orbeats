
local pd <const> = playdate
local gfx <const> = pd.graphics

local exp <const> = math.exp
local max <const> = math.max
local min <const> = math.min

local initialRadius <const> = 5
local LODRadius <const> = 40
local LODWidth <const> = 20
local missedNoteRadius <const> = 140

class('Note').extends(Object)

function Note:init(spawnBeat, hitBeat, spd, width, pos, spin, dur)
    self.spawnBeat = spawnBeat -- the beat when the note is spawned
    self.hitBeat = hitBeat -- the beat when the note is supposed to be hit
    self.lifeLength = hitBeat-spawnBeat
    if spd ~= nil then self.spd = spd else self.spd = 1 end -- how quickly the note approaches the orbit
    if width ~= nil then self.width = width else self.width = 45 end
    self.hitPos = pos -- the position where the note will be hit
    if spin ~= nil then self.spin = spin else self.spin = 0 end
    self.currentPos = self.hitPos + self.spin -- the current position of the note
    self.radius = initialRadius
    if dur ~= nil and dur >= 0 then self.duration = dur else self.duration = 0 end
    self.startRadius = nil -- used for figuring out the points of a hold note
    self.endRadius = initialRadius -- only used if the note has a duration to it
    self.hitting = false -- only used to tell if your hitting a hold note
    self.finishBeat = nil -- used for drawing if you stop hitting a hold note mid-note
end

local oldRadius
local beatsSinceSpawn
function Note:update(currentBeat, orbitRadius)
    oldRadius = self.radius
    beatsSinceSpawn = currentBeat-self.spawnBeat

    -- this formula creates an exponential graph connecting two points (spawnBeat,initialRadius and hitBeat,orbitRadius) in the vector space of beats and radii,
    -- with how quickly the graph increases in radius determined by self.spd
    -- self.radius = ((orbitRadius-initialRadius)/(math.exp(self.spd*self.hitBeat)-math.exp(self.spd*self.spawnBeat)))*(math.exp(self.spd*currentBeat)-math.exp(self.spd*self.spawnBeat))+initialRadius
    if not self.hitting then
        if self.finishBeat == nil then
            self.radius = min(max(initialRadius, ((orbitRadius-initialRadius)/(exp(self.spd*self.lifeLength)-1))*(exp(self.spd*beatsSinceSpawn)-1)+initialRadius), missedNoteRadius)
        else
            self.radius = min(max(initialRadius, ((orbitRadius-initialRadius)/(exp(self.spd*self.lifeLength)-1))*(exp(self.spd*(beatsSinceSpawn-(self.finishBeat-self.hitBeat)))-1)+initialRadius), missedNoteRadius)
        end
    end

    if self.duration > 0 then
        self.endRadius = max(initialRadius, ((orbitRadius-initialRadius)/(exp(self.spd*self.lifeLength)-1))*(exp(self.spd*(beatsSinceSpawn-self.duration))-1)+initialRadius)
    else
        self.endRadius = self.radius
    end

    -- -- this formula creates a linear graph that passes through a point determined by the hitBeat and hitPos in the vector space of beats and positions,
    -- -- with the slope determined by self.spin
    -- self.currentPos = self.spin*(currentBeat-self.hitBeat)+self.hitPos

    -- this function creates a linear graph that passes through two points in the vector space of beats and position.
    -- the first point is the spawnBeat and the spinPos (which is how many degrees away it spins in from),
    -- the second point is the hitBeat and the position where it will be hit.
    local spinPos = self.hitPos + self.spin
    self.currentPos = ((self.hitPos - spinPos)/(self.hitBeat - self.spawnBeat))*(currentBeat - self.spawnBeat) + spinPos

    -- keep the position between 0 and 360 degrees
    while self.currentPos > 360 do
        self.currentPos -= 360
    end
    while self.currentPos < 0 do
        self.currentPos += 360
    end

    return oldRadius, "note"
end

local noteStartAngle, noteEndAngle
local lineStartX1, lineStartY1
local lineStartX2, lineStartY2
local lineEndX1, lineEndY1
local lineEndX2, lineEndY2
function Note:draw(x, y, rad) -- rad is the orbit radius
    if self.radius == initialRadius then return end

    noteStartAngle, noteEndAngle = self:getNoteAngles()

    --draw note
    -- gfx.setColor(gfx.kColorBlack) -- now handled in game.lua
	gfx.setLineWidth(5*(self.radius/rad))
    -- dither via stencil if beyond the orbit
    if self.radius > rad then
        local distance = self.radius - rad
        local maxDist = missedNoteRadius - rad
        gfx.setStencilPattern(1-distance/maxDist)
    end
    lineStartX1, lineStartY1 = drawNoteArc(x, y, self.radius, noteStartAngle, noteEndAngle)

    --draw duration
    if self.duration > 0 then
        gfx.setLineWidth(self.endRadius/rad)
        if lineStartX1 == nil then lineStartX1 = x + self.radius * math.cos(math.rad(noteStartAngle-90)) end
        if lineStartY1 == nil then lineStartY1 = y + self.radius * math.sin(math.rad(noteStartAngle-90)) end
        lineStartX2 = x + self.radius * math.cos(math.rad(noteEndAngle-90))
        lineStartY2 = y + self.radius * math.sin(math.rad(noteEndAngle-90))
        lineEndX1 = x - self.endRadius * math.cos(math.rad(noteStartAngle+90))
        lineEndY1 = y - self.endRadius * math.sin(math.rad(noteStartAngle+90))
        lineEndX2 = x - self.endRadius * math.cos(math.rad(noteEndAngle+90))
        lineEndY2 = y - self.endRadius * math.sin(math.rad(noteEndAngle+90))
        drawNoteArc(x, y, self.endRadius, noteStartAngle, noteEndAngle)
        gfx.drawLine(lineStartX1, lineStartY1, lineEndX1, lineEndY1)
        gfx.drawLine(lineStartX2, lineStartY2, lineEndX2, lineEndY2)
    end
    if self.radius > rad then gfx.clearStencil() end -- reset stencil
end

function Note:getNoteAngles()
    return self.currentPos - (self.width/2), self.currentPos + (self.width/2)
end

function Note:beginHitting(orbitRadius, isPerfect)
    self.hitting = true
    if isPerfect ~= nil and isPerfect then self.startRadius = orbitRadius else self.startRadius = self.radius end
    self.radius = orbitRadius
end

function Note:resumeHitting(orbitRadius)
    self.hitting = true
    self.radius = orbitRadius
end

function Note:finishHitting(currentBeat)
    self.hitting = false
    self.finishBeat = currentBeat
end


function drawNoteArc(x, y, r, startAngle, endAngle)
    local width  = endAngle-startAngle
    if r <= LODRadius or width <= LODWidth or endAngle == nil then
        local px = x + r * math.cos(math.rad(startAngle-90))
        local py = y + r * math.sin(math.rad(startAngle-90))
        drawLineArc(x, y, px, py, width)
        return px, py
    else
        gfx.drawArc(x, y, r, startAngle, endAngle)
        return nil, nil
    end
    -- local px = x + r * math.cos(math.rad(startAngle-90))
    -- local py = y + r * math.sin(math.rad(startAngle-90))
    -- drawZapTest(x, y, px, py, width, r)
    -- return px, py
end

local x1, y1
local dx, dy
local theta
local steps, steppedTheta
local ctheta, stheta
local x2 ,y2
local stepSize <const> = 22.5 -- in degrees
local iStepSize <const> = 1/stepSize
function drawLineArc(x, y, px, py, length)
    x1, y1 = px, py
    dx, dy = x1 - x, y1 - y
    theta = math.rad(length)
    steps = max(math.floor(length*iStepSize), 1)
    steppedTheta = theta/steps
    ctheta = math.cos(steppedTheta)
    stheta = math.sin(steppedTheta)
    for i=steps,1,-1 do
        x2 = ctheta*dx - stheta*dy
        y2 = stheta*dx + ctheta*dy
        gfx.drawLine(x1, y1, x2+x, y2+y)
        dx = x2
        dy = y2
        x1 = x2+x
        y1 = y2+y
    end
end

-- local rand <const> = math.random
-- math.randomseed(pd.getSecondsSinceEpoch())
-- local offset <const> = {m = -6, n = 6}
-- local iHalfMissedR <const> = 1/(missedNoteRadius*0.5)
-- local rScale
-- local xr, yr
-- local xs, ys
-- local x1r, y1r

-- function drawZapTest(x, y, px, py, length, r)
--     rScale = r*iHalfMissedR
--     theta = math.rad(length)
--     steps = max(math.floor(length*iStepSize), 2)
--     steppedTheta = theta/steps
--     ctheta = math.cos(steppedTheta)
--     stheta = math.sin(steppedTheta)
    
--     for arcs=1,2 do
--         x1, y1 = px, py
--         dx, dy = x1 - x, y1 - y
--         for i=steps,1,-1 do
--             x2 = ctheta*dx - stheta*dy
--             y2 = stheta*dx + ctheta*dy
--             xr, yr = rand(offset.m, offset.n)*rScale, rand(offset.m, offset.n)*rScale
--             xs, ys = x2+x+xr, y2+y+yr
--             if i == steps then
--                 gfx.drawLine(x1, y1, xs, ys)
--             elseif i == 1 then
--                 gfx.drawLine(x1r, y1r, x2+x, y2+y)
--             else
--                 gfx.drawLine(x1r, y1r, xs, ys)
--             end
--             dx = x2
--             dy = y2
--             x1 = x2+x
--             y1 = y2+y
--             x1r = xs
--             y1r = ys
--         end
--     end

-- end