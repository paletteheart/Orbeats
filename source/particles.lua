
-- Heavily copied from PossiblyAxolotl's pdParticles library.

local pd <const> = playdate
local gfx <const> = pd.graphics

local screenWidth <const> = 400
local screenHeight <const> = 240

local maxParticles <const> = 10

local size <const> = {12,32}
local decay <const> = 1
local speed <const> = {1,4}
local thickness <const> = {0,2}

-- cache particle images
local function cacheParticles()
    local cache = {}
    -- get all possible thicknesses
    local t = {}
    for i=thickness[1], thickness[2] do
        table.insert(t, i)
    end

    local qDecay = decay*0.25
    local qSize = {}
    qSize[1] = size[1]*0.25
    qSize[2] = size[2]*0.25

    -- loop through each thickness
    gfx.setColor(gfx.kColorBlack)
    local imgAmount = math.floor(qSize[2]/qDecay)
    for i=#t,1,-1 do
        cache[t[i]] = {}
        -- loop through each size
        for j=imgAmount,1,-1 do
            local s = qSize[2]-(imgAmount-j)*qDecay
            -- stop if the size is 0
            if s <= 0 then break end
            
            local imgSize = math.max(s*2+math.max(t[i],0), 1)
            local img = gfx.image.new(imgSize, imgSize)
            -- draw into the image
            local o = t[i]*0.5
            gfx.pushContext(img)
                if t[i] < 1 then
                    gfx.fillCircleAtPoint(s+o,s+o,s)
                else
                    gfx.setLineWidth(t[i])
                    gfx.drawCircleAtPoint(s+o,s+o,s)
                end
            gfx.popContext()
            -- cache the image
            cache[t[i]][j] = img
        end
        -- print("particle images of thickness "..t[i]..": "..partCache[i]:getLength())
    end
    return cache
end
local partCache <const> = cacheParticles()

class("Particle").extends()

local partPool = {}

local function killPart(partList, partIndex)
    table.insert(partPool, partList[partIndex])
    table.remove(partList, partIndex)
end

function Particle:init(x, y)
    self.x = x or 0
    self.y = y or 0
    self.size = size
    self.spread = {0,359}
    self.speed = speed
    self.thickness = thickness
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
            killPart(partlist,part)
        end
    end

    return partlist
end

local dir
local speed
local part
function Particle:add(amount)
    for i = 1, amount, 1 do
        -- cap the amount of particles
        if #self.particles >= maxParticles then break end

        dir = math.random(self.spread[1],self.spread[2])
        speed = math.random(self.speed[1],self.speed[2])

        if #partPool > 0 then
            part = partPool[1]
            table.remove(partPool, 1)
            part.x = self.x
            part.y = self.y
            part.size = math.random(self.size[1],self.size[2])
            part.thickness = math.random(self.thickness[1],self.thickness[2])
            part.xStep = math.sin(math.rad(dir)) * speed
            part.yStep = -math.cos(math.rad(dir)) * speed
        else
            part = {
                x = self.x,
                y = self.y,
                size = math.random(self.size[1],self.size[2]),
                thickness = math.random(self.thickness[1],self.thickness[2]),
                xStep = math.sin(math.rad(dir)) * speed,
                yStep = -math.cos(math.rad(dir)) * speed
            }
        end

        self.particles[#self.particles+1] = part
    end
end

local circ
local oobHorz
local oobVert
function Particle:update()
    for part = math.min(maxParticles, #self.particles), 1, -1 do

        circ = self.particles[part]
        -- circ = partPool[self.particles[part]]

        -- cull particles that are out of bounds (off-screen)
        oobHorz = circ.x >= screenWidth+circ.size or circ.x <= -circ.size
        oobVert = circ.y >= screenHeight+circ.size or circ.y <= -circ.size
        if oobHorz or oobVert then
            killPart(self.particles,part)
        else
            -- draw the cached particle image
            partCache[circ.thickness][circ.size]:drawCentered(circ.x, circ.y)

            circ.x += circ.xStep
            circ.y += circ.yStep

            self.particles[part] = circ
        end
    end

    -- cull excess particles
    for i=maxParticles,#self.particles do
        killPart(self.particles,i)
    end

    decayPart(self.particles, decay)
end