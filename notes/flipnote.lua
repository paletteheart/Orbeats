
import "note"

local pd <const> = playdate
local gfx <const> = pd.graphics

class('FlipNote').extends(Note)

function FlipNote:update(currentBeat, orbitRadius)
    local returning = FlipNote.super.update(self, currentBeat, orbitRadius)
    returning["noteType"] = "flipnote"

    return returning
end

function FlipNote:draw(x, y, rad)
    local noteStartAngle, noteEndAngle = self:getNoteAngles()

    --draw note
    gfx.setColor(gfx.kColorBlack)
	gfx.setLineWidth(5*(self.radius/rad))
    gfx.drawArc(x, y, self.radius, noteStartAngle, noteEndAngle)
    --draw lines
    local lineStartX1 = x + self.radius * math.cos(math.rad(noteStartAngle-90))
    local lineStartY1 = y + self.radius * math.sin(math.rad(noteStartAngle-90))
    local lineStartX2 = x + self.radius * math.cos(math.rad(noteEndAngle-90))
    local lineStartY2 = y + self.radius * math.sin(math.rad(noteEndAngle-90))
    local lineEndX = x - self.radius * math.cos(math.rad(self.currentPos-90))
    local lineEndY = y - self.radius * math.sin(math.rad(self.currentPos-90))
    gfx.setColor(gfx.kColorBlack)
	gfx.setLineWidth(1*(self.radius/rad))
    gfx.drawLine(lineStartX1, lineStartY1, lineEndX, lineEndY)
    gfx.drawLine(lineStartX2, lineStartY2, lineEndX, lineEndY)
end