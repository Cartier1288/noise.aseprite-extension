local utils = require("utils")

local IBuffer = { }

-- NOTE: IBuffer in lua is handled slightly different from IBuffer in C++
-- 
-- here the pixels are packed directly into the elements themselves instead of being their own
-- objects. This is to avoid the overhead of creating many objects in Lua + the concern of always
-- passing by reference + the overhead of iterating over many small lists...
-- 
-- the consequence is that elements are set individually instead of by pixel, and therefore indices
-- are scaled by the depth
function IBuffer:new(width, height, depth, default) -- noexcept(false)
    local this = { }
    setmetatable(this, self)
    self.__index = self

    this.width = width; this.width1 = this.width-1
    this.height = height; this.height1 = this.height-1
    this.depth = depth

    this.default = default or 0

    this.length = width * height * depth

    this.elements = { }
    this.elements[this.length] = 0

    this:fill(this.default)

    return this
end


function IBuffer:pos_to_idx(x, y, z)
    return (y * self.width + x) * self.depth + z + 1
end

-- note: untested, just a guess lol
function IBuffer:idx_to_pos(idx)
    idx = idx - 1
    local y = idx % (self.width * self.depth)
    local x = (idx - (y * self.width)) % self.depth
    local z = idx - (y * self.width + x) * self.depth
    return x,y,z
end

function IBuffer:set_idx(idx, val)
    self.elements[idx] = val
end

function IBuffer:get_idx(idx)
    return self.elements[idx]
end

function IBuffer:set(x, y, z, val)
    self.elements[self:pos_to_idx(x,y,z)] = val
end

function IBuffer:get(x, y, z)
    return self.elements[self:pos_to_idx(x,y,z)]
end

function IBuffer:get_or_default(x, y, z)
    if x < 0 or x >= self.width or
       y < 0 or y >= self.height then
        return self.default
    end
    return self.elements[self:pos_to_idx(x,y,z)]
end

function IBuffer:get_or_loop(x, y, z)
    x = x % self.width
    y = y % self.height
    return self.elements[self:pos_to_idx(x,y,z)]
end

function IBuffer:get_or_clamp(x, y, z)
    x = math.min(math.max(0, x), self.width1)
    y = math.min(math.max(0, y), self.height1)
    return self.elements[self:pos_to_idx(x,y,z)]
end

function IBuffer:fill(val)
    local length = self.length
    local elements = self.elements
    for i=1,length do
        elements[i] = val
    end
end

function IBuffer:clone()
    local buffer = IBuffer:new(self.width, self.height, self.depth, self.default)

    local length = self.length
    local e1 = self.elements
    local e2 = buffer.elements
    for i=1,length do
        e2[i] = e1[i]
    end

    return buffer
end

-- wholesale copy the elements 
function IBuffer:to_array()
    local length = self.length

    local e1 = self.elements
    local e2 = { }; e2[length] = 0
    for i=1,length do
        e2[i] = e1[i]
    end

    return e2
end

-- iterates over _pixels_, idx skips by depth each iteration
-- offset here refers to the element in the pixel that the idx will refer to
function IBuffer:iterate(offset)
    offset = offset or 0
    local i = 1 + offset - self.depth

    local buffer = self
    local pixel = {
        x=-1, y=0, idx=i
    }
    function pixel:get(plus)
        plus = plus or 0
        return buffer:get_idx(self.idx + plus)
    end
    function pixel:put(plus, color)
        buffer:set_idx(self.idx + plus, color)
    end

    local n = self.length
    return function()
        i = i + self.depth
        pixel.idx = i

        pixel.x = pixel.x + 1
        if pixel.x >= self.width then
            pixel.x = 0
            pixel.y = pixel.y + 1
        end

        if i < n then
            return pixel
        end
    end
end

return IBuffer