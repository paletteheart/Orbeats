
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
    lineStartX1, lineStartY1, lineStartX2, lineStartY2 = drawNoteArc(x, y, self.radius, noteStartAngle, noteEndAngle, self.steps, self.ctheta, self.stheta, self.isHold, self.isHold)

    --draw duration
    if self.isHold then
        gfx.setLineWidth(self.endRadius/rad)
        gfx.setColor(col)
        lineEndX1, lineEndY1, lineEndX2, lineEndY2 = drawNoteArc(x, y, self.endRadius, noteStartAngle, noteEndAngle, self.steps, self.ctheta, self.stheta, true, true)
        gfx.drawLine(lineStartX1, lineStartY1, lineEndX1, lineEndY1)
        gfx.drawLine(lineStartX2, lineStartY2, lineEndX2, lineEndY2)
    end
    if self.radius > rad then gfx.clearStencil() end -- reset stencil
end