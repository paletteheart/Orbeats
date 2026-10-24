
import "note"
import "settings"

local pd <const> = playdate
local gfx <const> = pd.graphics

local missedNoteRadius <const> = 140

class("SlideNote").extends(Note)

function SlideNote:update(currentBeat, orbitRadius)
    local oldRadius, newRadius, position, endRadius, hitting, endBeat, hitBeat, speed, noteType = SlideNote.super.update(self, currentBeat, orbitRadius)
    noteType = "slidenote"

    return oldRadius, newRadius, position, endRadius, hitting, endBeat, hitBeat, speed, noteType
end

function SlideNote:draw(x, y, rad)
    local noteStartAngle, noteEndAngle = self:getNoteAngles()

    --draw note
    -- gfx.setColor(gfx.kColorBlack)
    gfx.setPattern(notePatterns[settings.notePattern])
    -- gfx.setDitherPattern(0.5)
	gfx.setLineWidth(5*(self.radius/rad))
    -- dither via stencil if beyond the orbit
    if self.radius > rad then
        local distance = self.radius - rad
        local maxDist = missedNoteRadius - rad
        gfx.setStencilPattern(1-distance/maxDist)
    end
    local lineStartX1, lineStartY1 = drawNoteArc(x, y, self.radius, noteStartAngle, noteEndAngle)

    -- draw duration
    if self.duration > 0 then
        -- gfx.setColor(gfx.kColorBlack) -- handled in game.lua
        gfx.setLineWidth(self.endRadius/rad)
        if lineStartX1 == nil then lineStartX1 = x + self.radius * math.cos(math.rad(noteStartAngle-90)) end
        if lineStartY1 == nil then lineStartY1 = y + self.radius * math.sin(math.rad(noteStartAngle-90)) end
        local lineStartX2 = x + self.radius * math.cos(math.rad(noteEndAngle-90))
        local lineStartY2 = y + self.radius * math.sin(math.rad(noteEndAngle-90))
        local lineEndX1 = x - self.endRadius * math.cos(math.rad(noteStartAngle+90))
        local lineEndY1 = y - self.endRadius * math.sin(math.rad(noteStartAngle+90))
        local lineEndX2 = x - self.endRadius * math.cos(math.rad(noteEndAngle+90))
        local lineEndY2 = y - self.endRadius * math.sin(math.rad(noteEndAngle+90))
        drawNoteArc(x, y, self.endRadius, noteStartAngle, noteEndAngle)
        gfx.drawLine(lineStartX1, lineStartY1, lineEndX1, lineEndY1)
        gfx.drawLine(lineStartX2, lineStartY2, lineEndX2, lineEndY2)
    end
    if self.radius > rad then gfx.clearStencil() end -- reset stencil
end