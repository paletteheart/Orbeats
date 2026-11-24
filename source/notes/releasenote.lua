
import "note"

local pd <const> = playdate
local gfx <const> = pd.graphics

local exp <const> = math.exp
local max <const> = math.max
local min <const> = math.min

local missedNoteRadius <const> = 140
local initialRadius <const> = 5

class('ReleaseNote').extends(Note)

local oldRadius
local beatsSinceSpawn
local spinPos
function ReleaseNote:update(currentBeat, orbitRadius)
    oldRadius = self.radius
    beatsSinceSpawn = currentBeat-self.spawnBeat

    -- this formula creates an exponential graph connecting two points (spawnBeat,initialRadius and hitBeat,orbitRadius) in the vector space of beats and radii,
    -- with how quickly the graph increases in radius determined by self.spd
    -- self.radius = ((orbitRadius-initialRadius)/(math.exp(self.spd*self.hitBeat)-math.exp(self.spd*self.spawnBeat)))*(math.exp(self.spd*currentBeat)-math.exp(self.spd*self.spawnBeat))+initialRadius
    self.radius = min(max(initialRadius, ((orbitRadius-initialRadius)/(exp(self.spd*self.lifeLength)-1))*(exp(self.spd*beatsSinceSpawn)-1)+initialRadius), missedNoteRadius)


    self.endRadius = self.radius

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
local steps
local offsetAngle
local xa1, ya1, xa2, ya2, dxa, dya
local xb1, yb1, xb2, yb2, dxb, dyb
local xc1, yc1, xc2, yc2, dxc, dyc
local theta, ctheta, stheta
function ReleaseNote:draw(x, y, rad)
    if self.radius == initialRadius then return end

    noteStartAngle, noteEndAngle = self:getNoteAngles()

    --draw note
    -- gfx.setColor(gfx.kColorBlack) -- handled in game.lua
	gfx.setLineWidth(self.radius/rad)
    -- dither via stencil if beyond the orbit
    if self.radius > rad then
        distance = self.radius - rad
        maxDist = missedNoteRadius - rad
        gfx.setStencilPattern(1-distance/maxDist)
    end
    drawNoteArc(x, y, self.radius, noteStartAngle, noteEndAngle)

    --draw tris
    steps = max(math.ceil(self.width/45)-1, 1)
    offsetAngle = noteStartAngle-min(45, (self.width/steps)/2)

    xa1 = x + (self.radius*0.8) * math.cos(math.rad(offsetAngle-90))
    ya1 = y + (self.radius*0.8) * math.sin(math.rad(offsetAngle-90))
    dxa, dya = xa1 - x, ya1 - y

    xb1 = x + (self.radius*0.9) * math.cos(math.rad(offsetAngle-95))
    yb1 = y + (self.radius*0.9) * math.sin(math.rad(offsetAngle-95))
    dxb, dyb = xb1 - x, yb1 - y

    xc1 = x + (self.radius*0.9) * math.cos(math.rad(offsetAngle-85))
    yc1 = y + (self.radius*0.9) * math.sin(math.rad(offsetAngle-85))
    dxc, dyc = xc1 - x, yc1 - y

    theta = math.rad(self.width)
    ctheta = math.cos(theta/steps)
    stheta = math.sin(theta/steps)
    
    for i=steps,1,-1 do
        xa2 = ctheta*dxa - stheta*dya
        ya2 = stheta*dxa + ctheta*dya
        xb2 = ctheta*dxb - stheta*dyb
        yb2 = stheta*dxb + ctheta*dyb
        xc2 = ctheta*dxc - stheta*dyc
        yc2 = stheta*dxc + ctheta*dyc

        gfx.fillTriangle(xa2+x, ya2+y, xb2+x, yb2+y, xc2+x, yc2+y)
        dxa, dya = xa2, ya2
        xa1, ya1 = xa2+x, ya2+y
        dxb, dyb = xb2, yb2
        xb1, yb1 = xb2+x, yb2+y
        dxc, dyc = xc2, yc2
        xc1, yc1 = xc2+x, yc2+y
    end

    if self.radius > rad then gfx.clearStencil() end -- reset stencil

end