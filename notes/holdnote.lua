
import "note"
import "settings"

local pd <const> = playdate
local gfx <const> = pd.graphics

class("HoldNote").extends(Note)

function HoldNote:update(currentBeat, orbitRadius)
    local returning = HoldNote.super.update(self, currentBeat, orbitRadius)
    returning["noteType"] = "holdnote"

    return returning
end

function HoldNote:draw(x, y, rad)
    local noteStartAngle, noteEndAngle = self:getNoteAngles()

    --draw note
    -- gfx.setColor(gfx.kColorBlack)
    gfx.setPattern(notePatterns[settings.notePattern])
    -- gfx.setDitherPattern(0.5)
	gfx.setLineWidth(5*(self.radius/rad))
    gfx.drawArc(x, y, self.radius, noteStartAngle, noteEndAngle)

    -- draw duration
    if self.duration > 0 then
        gfx.setColor(gfx.kColorBlack)
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