local utils = require("utils.utils-misc")

local ConvMatrix = { }

-- todo: make this its own option, e.g. custom convolutional matrix button in GUI
function ConvMatrix:new(width, height)
    local this = { }
    setmetatable(this, self)
    self.__index = self

    this.width = width
    this.height = height

    this.length = this.width * this.height

    this.elements = { }
    this.elements[this.length] = 0

    if width%2 == 0 or height%2 == 0 then
        error("invalid convolution matrix dimensions: must be odd")
    end

    -- e.g., the offset from the convolution coordinate that the matrix starts at
    this.xstart = -math.floor(this.width/2)
    this.ystart = -math.floor(this.height/2)

    this:_generate_offset_matrix()

    return this
end

function ConvMatrix:pos_to_idx(x, y)
    return y * self.width + x + 1
end

function ConvMatrix:set(x, y, value)
    self.elements[self:pos_to_idx(x, y)] = value
end


function ConvMatrix:sum()
    local total = 0

    for i=1,self.length do
        total = total + self.elements[i]
    end

    return total
end

-- same length as the number of elements in convolution, iterable just like elements
-- since offsets are inserted in the same order as elements
function ConvMatrix:_generate_offset_matrix()
    local offsets = { }
    self.offsets = offsets

    for y=0,self.height-1 do
        for x=0,self.width-1 do
            table.insert(offsets, {
                x = self.xstart + x,
                y = self.ystart + y
            })
        end
    end
end

function ConvMatrix:normalize()
    local total = self:sum()

    for i=1,self.length do
        self.elements[i] = self.elements[i] / total
    end
end

function ConvMatrix:apply(buffer, x, y, z)
    local val = 0

    for i=1,self.length do
        local offsets = self.offsets[i]
        local el = self.elements[i]

        val = val + el * buffer:get_or_clamp(x + offsets.x, y + offsets.y, z)
    end

    return val
end


return {
    ConvMatrix = ConvMatrix
}