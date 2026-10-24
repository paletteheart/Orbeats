
-- Heavily copied from PossiblyAxolotl's pdParticles library.

local pd <const> = playdate
local gfx <const> = pd.graphics

local screenWidth <const> = 400
local screenHeight <const> = 240

local maxParticles <const> = 10

local size <const> = {3,8}
local decay <const> = 0.25
local speed <const> = {1,4}
local thickness <const> = {0,2}

-- cache particle images
local partCache = {}
local function cacheParticles()

    -- get all possible thicknesses
    local t = {}
    for i=thickness[1], thickness[2] do
        table.insert(t, i)
    end

    -- loop through each thickness
    gfx.setColor(gfx.kColorBlack)
    local imgAmount = math.floor(size[2]/decay)
    for i=#t,1,-1 do
        partCache[t[i]] = gfx.imagetable.new(imgAmount)
        -- loop through each size
        for j=imgAmount,1,-1 do
            local s = size[2]-(imgAmount-j)*decay
            -- stop if the size is 0
            if s <= 0 then break end
            
            local imgSize = math.max(s*2+math.max(t[i],0), 1)
            local img = gfx.image.new(imgSize, imgSize)
            -- draw into the image
            gfx.pushContext(img)
                if t[i] < 1 then
                    gfx.fillCircleAtPoint(s,s,s)
                else
                    gfx.setLineWidth(t[i])
                    gfx.drawCircleAtPoint(s,s,s)
                end
            gfx.popContext()
            -- cache the image
            partCache[t[i]]:setImage(j, img)
        end
        -- print("particle images of thickness "..t[i]..": "..partCache[i]:getLength())
    end
end
cacheParticles()

class("Particle").extends()

function Particle:init(x, y)
    self.x = x or 0
    self.y = y or 0
    self.size = size
    self.spread = {0,359}
    self.speed = speed
    self.acceleration = {0, 0}
    self.thickness = thickness
    self.decay = decay
    self.particles = {}
end

function Particle:moveTo(x, y)
    self.x, self.y = x, y
end

function Particle:setSpread(min,max)
    self.spread = {min, max or min}
end

local function decayPart(partlist, decay)
    for part = #partlist, 1, -1 do
        local particle = partlist[part]
        particle.size -= decay

        if particle.size <= 0 then
            particle.size = 0
        end

        partlist[part] = particle
    end

    for part = #partlist, 1, -1 do
        local particle = partlist[part]
        if particle.size <= 0 then
            table.remove(partlist,part)
        end
    end

    return partlist
end

function Particle:add(amount)
    for i = 1, amount, 1 do
        -- cap the amount of particles
        if #self.particles >= maxParticles then break end

        local part = {
            x = self.x,
            y = self.y,
            dir = math.random(self.spread[1],self.spread[2]),
            size = math.random(self.size[1],self.size[2]),
            speed = math.random(self.speed[1],self.speed[2]),
            acceleration = math.random(self.acceleration[1],self.acceleration[2]),
            thickness = math.random(self.thickness[1],self.thickness[2]),
            decay = self.decay
        }

        self.particles[#self.particles+1] = part
    end
end

function Particle:update()
    for part = math.min(maxParticles, #self.particles), 1, -1 do

        local circ = self.particles[part]

        -- cull particles that are out of bounds (off-screen)
        local oobHorz = circ.x >= screenWidth+circ.size or circ.x <= -circ.size
        local oobVert = circ.y >= screenHeight+circ.size or circ.y <= -circ.size
        if oobHorz or oobVert then
            table.remove(self.particles,part)
        else
            -- draw the cached particle image
            partCache[circ.thickness]:getImage(math.floor(circ.size/decay)):drawCentered(circ.x, circ.y)

            circ.x += math.sin(math.rad(circ.dir)) * circ.speed
            circ.y -= math.cos(math.rad(circ.dir)) * circ.speed
            
            circ.speed += circ.acceleration / 100

            self.particles[part] = circ
        end
    end

    -- cull excess particles
    for i=maxParticles,#self.particles do
        table.remove(self.particles,i)
    end

    decayPart(self.particles, decay)
end