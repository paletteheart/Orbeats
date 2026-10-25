
import "note"

local pd <const> = playdate
local gfx <const> = pd.graphics

local exp <const> = math.exp
local max <const> = math.max
local min <const> = math.min

local missedNoteRadius <const> = 140
local initialRadius <const> = 5

class('ReleaseNote').extends(Note)

function ReleaseNote:update(currentBeat, orbitRadius)
    local oldRadius = self.radius
    local beatsSinceSpawn
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
    local spinPos = self.hitPos + self.spin
    self.currentPos = ((self.hitPos - spinPos)/(self.hitBeat - self.spawnBeat))*(currentBeat - self.spawnBeat) + spinPos

    -- keep the position between 0 and 360 degrees
    while self.currentPos > 360 do
        self.currentPos -= 360
    end
    while self.currentPos < 0 do
        self.currentPos += 360
    end

    return oldRadius, self.radius, self.currentPos, self.endRadius, self.hitting, self.duration + self.hitBeat, self.hitBeat, self.spd, "releasenote"

end

function ReleaseNote:draw(x, y, rad)
    if self.radius == initialRadius then return end

    local noteStartAngle, noteEndAngle = self:getNoteAngles()

    --draw note
    -- gfx.setColor(gfx.kColorBlack) -- handled in game.lua
	gfx.setLineWidth(self.radius/rad)
    -- dither via stencil if beyond the orbit
    if self.radius > rad then
        local distance = self.radius - rad
        local maxDist = missedNoteRadius - rad
        gfx.setStencilPattern(1-distance/maxDist)
    end
    drawNoteArc(x, y, self.radius, noteStartAngle, noteEndAngle)

    --draw tris
    local steps = max(math.floor(self.width/45)-1, 1)
    local offsetAngle = noteStartAngle-min(45, (self.width/steps)/2)

    local xa1 = x + (self.radius*0.8) * math.cos(math.rad(offsetAngle-90))
    local ya1 = y + (self.radius*0.8) * math.sin(math.rad(offsetAngle-90))
    local dxa, dya = xa1 - x, ya1 - y

    local xb1 = x + (self.radius*0.9) * math.cos(math.rad(offsetAngle-95))
    local yb1 = y + (self.radius*0.9) * math.sin(math.rad(offsetAngle-95))
    local dxb, dyb = xb1 - x, yb1 - y

    local xc1 = x + (self.radius*0.9) * math.cos(math.rad(offsetAngle-85))
    local yc1 = y + (self.radius*0.9) * math.sin(math.rad(offsetAngle-85))
    local dxc, dyc = xc1 - x, yc1 - y

    local theta = math.rad(self.width)
    local ctheta = math.cos(theta/steps)
    local stheta = math.sin(theta/steps)
    
    for i=steps,1,-1 do
        local xa2 = ctheta*dxa - stheta*dya
        local ya2 = stheta*dxa + ctheta*dya
        local xb2 = ctheta*dxb - stheta*dyb
        local yb2 = stheta*dxb + ctheta*dyb
        local xc2 = ctheta*dxc - stheta*dyc
        local yc2 = stheta*dxc + ctheta*dyc

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