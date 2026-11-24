
import "note"
import "settings"

local pd <const> = playdate
local gfx <const> = pd.graphics

local missedNoteRadius <const> = 140

class("SlideNote").extends(Note)

local noteStartAngle, noteEndAngle
local distance, maxDist
local lineStartX1, lineStartY1
local lineStartX2, lineStartY2
local lineEndX1, lineEndY1
local lineEndX2, lineEndY2
local col
function SlideNote:draw(x, y, rad) -- rad is the orbit radius
    if self.radius == initialRadius then return end

    noteStartAngle, noteEndAngle = self:getNoteAngles()

    --draw note
    -- gfx.setColor(gfx.kColorBlack) -- now handled in game.lua
    col = gfx.getColor()
    gfx.setPattern(notePatterns[settings.notePattern])
	gfx.setLineWidth(5*(self.radius/rad))
    -- dither via stencil if beyond the orbit
    if self.radius > rad then
        distance = self.radius - rad
        maxDist = missedNoteRadius - rad
        gfx.setStencilPattern(1-distance/maxDist)
    end
    lineStartX1, lineStartY1 = drawNoteArc(x, y, self.radius, noteStartAngle, noteEndAngle)

    --draw duration
    if self.duration > 0 then
        gfx.setColor(col)
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