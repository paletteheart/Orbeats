
import "note"

local pd <const> = playdate
local gfx <const> = pd.graphics

local exp <const> = math.exp

local missedNoteRadius <const> = 140
local initialRadius <const> = 5

class('FlipNote').extends(Note)

function FlipNote:update(currentBeat, orbitRadius)
    local oldRadius = self.radius
    local beatsSinceSpawn
    beatsSinceSpawn = currentBeat-self.spawnBeat

    -- this formula creates an exponential graph connecting two points (spawnBeat,initialRadius and hitBeat,orbitRadius) in the vector space of beats and radii,
    -- with how quickly the graph increases in radius determined by self.spd
    -- self.radius = ((orbitRadius-initialRadius)/(math.exp(self.spd*self.hitBeat)-math.exp(self.spd*self.spawnBeat)))*(math.exp(self.spd*currentBeat)-math.exp(self.spd*self.spawnBeat))+initialRadius
    self.radius = ((orbitRadius-initialRadius)/(exp(self.spd*self.lifeLength)-1))*(exp(self.spd*beatsSinceSpawn)-1)+initialRadius

    self.endRadius = self.radius

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

    return oldRadius, self.radius, self.currentPos, self.endRadius, self.hitting, self.duration + self.hitBeat, self.hitBeat, self.spd, "flipnote"

end

function FlipNote:draw(x, y, rad)
    local noteStartAngle, noteEndAngle = self:getNoteAngles()

    --draw note
    -- gfx.setColor(gfx.kColorBlack) -- handled in game.lua
	gfx.setLineWidth(5*(self.radius/rad))
    -- dither via stencil if beyond the orbit
    if self.radius > rad then
        local distance = self.radius - rad
        local maxDist = missedNoteRadius - rad
        gfx.setStencilPattern(1-distance/maxDist)
    end
    local lineStartX1, lineStartY1 = drawNoteArc(x, y, self.radius, noteStartAngle, noteEndAngle)

    --draw lines
    if lineStartX1 == nil then lineStartX1 = x + self.radius * math.cos(math.rad(noteStartAngle-90)) end
    if lineStartY1 == nil then lineStartY1 = y + self.radius * math.sin(math.rad(noteStartAngle-90)) end
    local lineStartX2 = x + self.radius * math.cos(math.rad(noteEndAngle-90))
    local lineStartY2 = y + self.radius * math.sin(math.rad(noteEndAngle-90))
    local lineEndX = x - self.radius * math.cos(math.rad(self.currentPos-90))
    local lineEndY = y - self.radius * math.sin(math.rad(self.currentPos-90))
	gfx.setLineWidth(self.radius/rad)
    gfx.drawLine(lineStartX1, lineStartY1, lineEndX, lineEndY)
    gfx.drawLine(lineStartX2, lineStartY2, lineEndX, lineEndY)
    if self.radius > rad then gfx.clearStencil() end -- reset stencil

end