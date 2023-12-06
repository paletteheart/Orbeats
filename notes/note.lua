
local pd <const> = playdate
local gfx <const> = pd.graphics

local initialRadius <const> = 5

class('Note').extends(Object)

function Note:init(spawnBeat, hitBeat, spd, width, pos, spin)
    self.spawnBeat = spawnBeat -- the beat when the note is spawned
    self.hitBeat = hitBeat -- the beat when the note is supposed to be hit
    self.lifeLength = hitBeat-spawnBeat
    self.spd = spd -- how quickly the note approaches the 
    self.width = width
    self.hitPos = pos -- the position where the note will be hit
    self.currentPos = pos -- the current position of the note
    self.spin = spin
    self.radius = initialRadius
end

function Note:update(currentBeat, orbitRadius)
    local oldRadius = self.radius
    local beatsSinceSpawn = currentBeat-self.spawnBeat

    -- this formula creates an exponential graph connecting two points (spawnBeat,initialRadius and hitBeat,orbitRadius) in the vector space of beats and radii,
    -- with how quickly the graph increases in radius determined by self.spd
    -- self.radius = ((orbitRadius-initialRadius)/(math.exp(self.spd*self.hitBeat)-math.exp(self.spd*self.spawnBeat)))*(math.exp(self.spd*currentBeat)-math.exp(self.spd*self.spawnBeat))+initialRadius
    self.radius = ((orbitRadius-initialRadius)/(math.exp(self.spd*self.lifeLength)-1))*(math.exp(self.spd*beatsSinceSpawn)-1)+initialRadius

    -- this formula creates a linear graph that passes through a point determined by the hitBeat and hitPos in the vector space of beats and positions,
    -- with the slope determined by self.spin
    self.currentPos = self.spin*(currentBeat-self.hitBeat)+self.hitPos

    -- keep the position between 0 and 360 degrees
    while self.currentPos > 360 do
        self.currentPos -= 360
    end
    while self.currentPos < 0 do
        self.currentPos += 360
    end

    return {oldRadius = oldRadius, newRadius = self.radius, position = self.currentPos, noteType = "note"}
end

function Note:draw(x, y, rad)
    local noteAngles = self:getNoteAngles()

    --draw note
    gfx.setColor(gfx.kColorBlack)
	gfx.setLineWidth(5*(self.radius/rad))
    gfx.drawArc(x, y, self.radius, noteAngles.startAngle, noteAngles.endAngle)
end

function Note:getNoteAngles()
    local startAngle = self.currentPos - (self.width/2)
    local endAngle = self.currentPos + (self.width/2)

    return {startAngle = startAngle, endAngle = endAngle}
end