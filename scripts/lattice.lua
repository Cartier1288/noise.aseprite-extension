local utils = require("utils")

Lattice2 = {
    width=10,
    height=10,
    cs=1, -- cellsize
    freq=0, -- > 0 means repeat every freq _cells_
}

function Lattice2:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.seed = o.seed or os.time()
    o.scaled_freq = o.freq * o.cs
    o.points = { }
    o.pointset = { }

    return o
end

function Lattice2:seed(seed)
    self.seed = seed
end

function Lattice2:apply_freq(cx, cy)
    if self.freq == 0 then
        return cx, cy
    else
        return cx % self.scaled_freq, cy % self.scaled_freq
    end
end

function Lattice2:get_corner(x, y)
    return
        math.floor(x / self.cs) * self.cs,
        math.floor(y / self.cs) * self.cs
end

function Lattice2:apply_ltc_seed(x, y)
    local cx, cy = self:apply_freq(self:get_corner(x,y))
    math.randomseed(cx + self.seed, cy + self.seed)
end

function Lattice2:getn(n, x, y)
    self:apply_ltc_seed(x,y)

    local rs = { }
    for i=1,n do
        rs[i] = math.random() * self.cs
    end

    return rs
end

function Lattice2:cell_width()
    return math.ceil(self.width/self.cs)
end

function Lattice2:cell_height()
    return math.ceil(self.height/self.cs)
end

-- returns an iterator over each cell, similar to Aseprite Image:pixels
function Lattice2:cells()
    local i = 0

    local cs = self.cs

    local cell = { x=-cs, y=0 }

    local n = self:cell_width() * self:cell_height()
    return function()
        i = i + 1

        cell.x = cell.x + cs
        if cell.x >= self.width then
            cell.x = 0
            cell.y = cell.y + cs
        end

        -- for convenience apply the seed here on every iteration
        self:apply_ltc_seed(cell.x, cell.y)

        if i <= n then
            return cell
        end
    end
end

function Lattice2:cell(x, y, gen)
    local cx, cy = self:get_corner(x,y)

    self:apply_ltc_seed(x,y)

    --local hash = string.format("%d,%d", cx, cx)

    --if self.pointset[hash] ~= nil then
    --    return self.points[hash]
    --else
        local points = { }

        -- get number of points from a Poisson distribution
        local n = gen()

        -- then randomly generate points within the cell, iterator pre-seeds each cell using unique 
        -- hash from position and seed
        for _=1,n do
            table.insert(points, {
                math.random()*self.cs + cx,
                math.random()*self.cs + cy,
            })
        end

        local cell = { x = cx, y = cy, points = points }
        --self.pointset[hash] = true
        --self.points[hash] = cell

        return cell
    --end
end

function Lattice2:ncells()
    return self:cell_width() * self:cell_height()
end