
local pd <const> = playdate
local gfx <const> = pd.graphics

local initialRadius <const> = 5

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
    self.endRadius = initialRadius -- only used if the note has a duration to it
    self.hitting = false -- only used to tell if your hitting a long note
    self.finishBeat = nil -- only used for drawing if you stop hitting a long note mid-note
end

function Note:update(currentBeat, orbitRadius)
    local oldRadius = self.radius
    local beatsSinceSpawn
    beatsSinceSpawn = currentBeat-self.spawnBeat

    -- this formula creates an exponential graph connecting two points (spawnBeat,initialRadius and hitBeat,orbitRadius) in the vector space of beats and radii,
    -- with how quickly the graph increases in radius determined by self.spd
    -- self.radius = ((orbitRadius-initialRadius)/(math.exp(self.spd*self.hitBeat)-math.exp(self.spd*self.spawnBeat)))*(math.exp(self.spd*currentBeat)-math.exp(self.spd*self.spawnBeat))+initialRadius
    if not self.hitting then
        if self.finishBeat == nil then
            self.radius = ((orbitRadius-initialRadius)/(math.exp(self.spd*self.lifeLength)-1))*(math.exp(self.spd*beatsSinceSpawn)-1)+initialRadius
        else
            self.radius = ((orbitRadius-initialRadius)/(math.exp(self.spd*self.lifeLength)-1))*(math.exp(self.spd*(beatsSinceSpawn-(self.finishBeat-self.hitBeat)))-1)+initialRadius
            -- print(beatsSinceSpawn-(self.finishBeat-self.hitBeat))
        end
    end

    if self.duration > 0 then
        self.endRadius = ((orbitRadius-initialRadius)/(math.exp(self.spd*self.lifeLength)-1))*(math.exp(self.spd*(beatsSinceSpawn-self.duration))-1)+initialRadius
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

    return {oldRadius = oldRadius, newRadius = self.radius, position = self.currentPos, noteType = "note", endRadius = self.endRadius, hitting = self.hitting, endBeat = self.duration + self.hitBeat, hitBeat = self.hitBeat}
end

function Note:draw(x, y, rad)
    local noteStartAngle, noteEndAngle = self:getNoteAngles()

    --draw note
    gfx.setColor(gfx.kColorBlack)
	gfx.setLineWidth(5*(self.radius/rad))
    gfx.drawArc(x, y, self.radius, noteStartAngle, noteEndAngle)

    --draw duration
    if self.duration > 0 then
        gfx.setLineWidth(self.endRadius/rad)
        gfx.drawArc(x, y, self.endRadius, noteStartAngle, noteEndAngle)
        local lineStartX1 = x + self.radius * math.cos(math.rad(noteStartAngle-90))
        local lineStartY1 = y + self.radius * math.sin(math.rad(noteStartAngle-90))
        local lineStartX2 = x + self.radius * math.cos(math.rad(noteEndAngle-90))
        local lineStartY2 = y + self.radius * math.sin(math.rad(noteEndAngle-90))
        local lineEndX1 = x - self.endRadius * math.cos(math.rad(noteStartAngle+90))
        local lineEndY1 = y - self.endRadius * math.sin(math.rad(noteStartAngle+90))
        local lineEndX2 = x - self.endRadius * math.cos(math.rad(noteEndAngle+90))
        local lineEndY2 = y - self.endRadius * math.sin(math.rad(noteEndAngle+90))
        gfx.drawLine(lineStartX1, lineStartY1, lineEndX1, lineEndY1)
        gfx.drawLine(lineStartX2, lineStartY2, lineEndX2, lineEndY2)
    end
end

function Note:getNoteAngles()
    local startAngle = self.currentPos - (self.width/2)
    local endAngle = self.currentPos + (self.width/2)

    return startAngle, endAngle
end

function Note:beginHitting(orbitRadius)
    self.hitting = true
    self.radius = orbitRadius
end

function Note:finishHitting(currentBeat)
    self.hitting = false
    self.finishBeat = currentBeat
end