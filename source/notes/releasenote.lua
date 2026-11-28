
import "note"

local pd <const> = playdate
local gfx <const> = pd.graphics

local exp <const> = math.exp
local max <const> = math.max
local min <const> = math.min
local sin <const> = math.sin
local cos <const> = math.cos
local rad <const> = math.rad
local ceil <const> = math.ceil

local missedNoteRadius <const> = 140
local initialRadius <const> = 5

class('ReleaseNote').extends(Note)

local arrowStepAngle <const> = 45 -- should be double the stepAngle in note.lua
function ReleaseNote:init(spawnBeat, hitBeat, spd, width, pos, spin, dur)
    ReleaseNote.super.init(self, spawnBeat, hitBeat, spd, width, pos, spin, dur)
    -- width never changes, so it's best these are only calculated once
    self.arrowsteps = max(ceil(self.steps*0.5)-1, 1)
    local arrowSteppedTheta = self.theta/self.arrowsteps
    self.arrowctheta = cos(arrowSteppedTheta)
    self.arrowstheta = sin(arrowSteppedTheta)
    self.arrowoffset = min(arrowStepAngle, (self.width/self.arrowsteps)*0.5)
end

local oldRadius
local beatsSinceSpawn
local spinPos
function ReleaseNote:update(currentBeat, orbitRadius)
    oldRadius = self.radius
    beatsSinceSpawn = currentBeat-self.spawnBeat

    -- this formula creates an exponential graph connecting two points (spawnBeat,initialRadius and hitBeat,orbitRadius) in the vector space of beats and radii,
    -- with how quickly the graph increases in radius determined by self.spd
    self.radius = min(max(initialRadius, ((orbitRadius-initialRadius)/(exp(self.spd*self.lifeLength)-1))*(exp(self.spd*beatsSinceSpawn)-1)+initialRadius), missedNoteRadius)


    self.endRadius = self.radius

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
local offsetAngle
local xa1, ya1, xa2, ya2, dxa, dya
local xb1, yb1, xb2, yb2, dxb, dyb
local xc2, yc2, dxc, dyc
local ctheta, stheta
local arrowBaseTheta <const> = rad(10)
local basectheta <const>, basestheta <const> = cos(arrowBaseTheta), sin(arrowBaseTheta)
function ReleaseNote:draw(x, y, radius)
    if self.radius == initialRadius then return end

    noteStartAngle, noteEndAngle = self:getNoteAngles()

    --draw note
    -- gfx.setColor(gfx.kColorBlack) -- handled in game.lua
	gfx.setLineWidth(self.radius/radius)
    -- dither via stencil if beyond the orbit
    if self.radius > radius then
        distance = self.radius - radius
        maxDist = missedNoteRadius - radius
        gfx.setStencilPattern(1-distance/maxDist)
    end
    drawNoteArc(x, y, self.radius, noteStartAngle, noteEndAngle, self.steps, self.ctheta, self.stheta)

    --draw tris
    offsetAngle = noteStartAngle-self.arrowoffset

    xa1, ya1 = pointFromCirclePosition(x, y, self.radius*0.8, offsetAngle-90)
    dxa, dya = xa1 - x, ya1 - y

    xb1, yb1 = pointFromCirclePosition(x, y, self.radius*0.9, offsetAngle-95)
    dxb, dyb = xb1 - x, yb1 - y

    -- calculate the position of xc and yc without using pointFromCirclePosition
    ctheta = basectheta
    stheta = basestheta
    xb2 = ctheta*dxb - stheta*dyb
    yb2 = stheta*dxb + ctheta*dyb

    dxc, dyc = xb2, yb2

    ctheta = self.arrowctheta
    stheta = self.arrowstheta
    
    for i=self.arrowsteps,1,-1 do
        xa2 = ctheta*dxa - stheta*dya
        ya2 = stheta*dxa + ctheta*dya

        xb2 = ctheta*dxb - stheta*dyb
        yb2 = stheta*dxb + ctheta*dyb

        xc2 = ctheta*dxc - stheta*dyc
        yc2 = stheta*dxc + ctheta*dyc

        gfx.fillTriangle(xa2+x, ya2+y, xb2+x, yb2+y, xc2+x, yc2+y)

        dxa, dya = xa2, ya2
        
        dxb, dyb = xb2, yb2

        dxc, dyc = xc2, yc2
    end

    if self.radius > radius then gfx.clearStencil() end -- reset stencil

end