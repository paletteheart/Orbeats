
local pd <const> = playdate
local gfx <const> = pd.graphics

local exp <const> = math.exp
local max <const> = math.max
local min <const> = math.min
local floor <const> = math.floor
local ceil <const> = math.ceil
local sin <const> = math.sin
local cos <const> = math.cos
local rad <const> = math.rad

local initialRadius <const> = 5
local LODRadius <const> = 40
local LODWidth <const> = 20
local missedNoteRadius <const> = 140

class('Note').extends(Object)

local stepSize <const> = 22.5 -- in degrees
local iStepSize <const> = 1/stepSize
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
    if dur ~= nil and dur >= 0 then
        self.duration = dur
        self.isHold = true
    else
        self.duration = 0
        self.isHold = false
    end
    self.startRadius = nil -- used for figuring out the points of a hold note
    self.endRadius = initialRadius -- only used if the note has a duration to it
    self.hitting = false -- only used to tell if your hitting a hold note
    self.finishBeat = nil -- used for drawing if you stop hitting a hold note mid-note

    -- LOD drawing values
    -- width never changes, so it's best these are only calculated once
    self.theta = rad(self.width)
    self.steps = max(ceil(self.width*iStepSize), 1)
    local steppedTheta = self.theta/self.steps
    self.ctheta = cos(steppedTheta)
    self.stheta = sin(steppedTheta)
end

local oldRadius
local beatsSinceSpawn
local spinPos
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

    if self.isHold then
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
    spinPos = self.hitPos + self.spin
    self.currentPos = ((self.hitPos - spinPos)/(self.hitBeat - self.spawnBeat))*(currentBeat - self.spawnBeat) + spinPos

    -- keep the position between 0 and 360 degrees
    while self.currentPos > 360 do
        self.currentPos -= 360
    end
    while self.currentPos < 0 do
        self.currentPos += 360
    end

    return oldRadius
end

local noteStartAngle, noteEndAngle
local distance, maxDist
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
        distance = self.radius - rad
        maxDist = missedNoteRadius - rad
        gfx.setStencilPattern(1-distance/maxDist)
    end
    lineStartX1, lineStartY1, lineStartX2, lineStartY2 = drawNoteArc(x, y, self.radius, noteStartAngle, noteEndAngle, self.steps, self.ctheta, self.stheta, self.isHold, self.isHold)

    --draw duration
    if self.isHold then
        gfx.setLineWidth(self.endRadius/rad)
        lineEndX1, lineEndY1, lineEndX2, lineEndY2 = drawNoteArc(x, y, self.endRadius, noteStartAngle, noteEndAngle, self.steps, self.ctheta, self.stheta, true, true)
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

local width
local px, py
local qx, qy
function drawNoteArc(x, y, r, startAngle, endAngle, steps, ctheta, stheta, forceReturnStart, forceReturnEnd)
    width  = endAngle-startAngle

    if not (r <= LODRadius or width <= LODWidth) then -- deleted "or endAngle == nil", not sure why it was there
        gfx.drawArc(x, y, r, startAngle, endAngle)

        px, py, qx, qy = nil, nil, nil, nil

        if forceReturnStart then px, py = pointFromCirclePosition(x, y, r, startAngle-90) end
        if forceReturnEnd then qx, qy = pointFromCirclePosition(x, y, r, endAngle-90) end

        return px, py, qx, qy
    end

    -- is LOD'd
    px, py = pointFromCirclePosition(x, y, r, startAngle-90)
    qx, qy = drawLineArc(x, y, px, py, steps, ctheta, stheta)
    return px, py, qx, qy

    -- px, py = pointFromCirclePosition(x, y, r, startAngle-90)
    -- drawZapTest(x, y, px, py, width, r)
    -- return px, py
end

local x1, y1
local dx, dy
local x2, y2
--- Used to quickly draw an approximation of an arc using lines.
---@param x number
---@param y number
---@param px number
---@param py number
---@param steps integer
---@param ctheta number
---@param stheta number
---@return number endX
---@return number endY
function drawLineArc(x, y, px, py, steps, ctheta, stheta)
    x1, y1 = px, py
    dx, dy = x1 - x, y1 - y
    for i=steps,1,-1 do
        x2 = ctheta*dx - stheta*dy
        y2 = stheta*dx + ctheta*dy
        gfx.drawLine(x1, y1, x2+x, y2+y)
        dx = x2
        dy = y2
        x1 = x2+x
        y1 = y2+y
    end
    return x1, y1 --return the endAngle position
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
--     theta = rad(length)
--     steps = max(floor(length*iStepSize), 2)
--     steppedTheta = theta/steps
--     ctheta = cos(steppedTheta)
--     stheta = sin(steppedTheta)
    
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