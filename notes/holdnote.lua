
import "note"

local pd <const> = playdate
local gfx <const> = pd.graphics

class("HoldNote").extends(Note)

function HoldNote:update(currentBeat, orbitRadius)
    local returning = HoldNote.super.update(self, currentBeat, orbitRadius)
    returning["noteType"] = "holdnote"

    return returning
end

function HoldNote:draw(x, y, rad)
    local noteAngles = self:getNoteAngles()

    --draw note
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(0.5)
	gfx.setLineWidth(5*(self.radius/rad))
    gfx.drawArc(x, y, self.radius, noteAngles.startAngle, noteAngles.endAngle)
end