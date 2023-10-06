-- more or less tries to follow the description of the algorithm from here:
-- https://dl.acm.org/doi/pdf/10.1145/237170.237267

-- Worley algorithm uses a lttice similar to Perlin to handle generating points

require("lattice")
local utils = require("utils")

local MIN_POINTS = 1 -- minimum points per cel, makes F(x) calculation faster if > 1 since we can 
                     -- drastically narrows down the range of points to calculate distance from

local function generate_points(seed, width, height, cellsize, mean)
    local ltc = Lattice2:new{
        seed=seed,
        width=width,
        height=height,
        cs=cellsize
    }

    local points = { }

    for cell in ltc:cells() do
        print(utils.dump(cell))

        -- get number of points from a Poisson distribution
        local n = math.max(MIN_POINTS, utils.rpoisson(mean))

        -- then randomly generate points within the cell, iterator pre-seeds each cell using unique 
        -- hash from position and seed
        for _=1,n do
            table.insert(points, {
                math.random()*ltc.cs + cell.x,
                math.random()*ltc.cs + cell.y,
            })
        end
    end

    print(utils.dump(points))
    print(ltc:ncells())
    print(#points)
    print("mean: ", mean, ", real: ", #points / ltc:ncells())

    return points
end
local function npointsp(mean)
    return math.max(MIN_POINTS, utils.rpoisson(mean))
end

local function Fn(ltc, n, x, y, options)
    local dfunc = options.distance_func

    local xfrom, yfrom = x-ltc.cs, y-ltc.cs
    local xto, yto = x+ltc.cs, y+ltc.cs

    local closest = { }

    local function gen() return npointsp(options.mean_points) end

    -- todo
    -- can't be bothered to try and figure out the logistics of cancelling rows / cells based off of
    -- current _n'th_ max distance
    for cx=xfrom,xto,ltc.cs do
        for cy=yfrom,yto,ltc.cs do
            local ccell = ltc:cell(cx, cy, gen)
            utils.nclosest(n, ccell.points, closest, x, y, dfunc)
        end
    end

    return closest
end

local function mean(n, arr)
    local val = 0
    for i=1,#arr do
        val = val + arr[i]
    end
    return val / #arr
end

local function wdiff(n, arr)
    return arr[2] - arr[1]
end

-- returns the nth element of an array, default combination
local function nth(n, arr)
    return arr[n]
end

-- str should fill in the followigng:
-- return function(a) return (${str}) end
local function create_combination(str)
    local wrapped = string.format("return function(n, a) return (%s) end", str)
    local func, err = load(wrapped)
    if func then
        local ok, mod = pcall(func)
        if ok then
            return mod
        else
            print("unexpected error when creating combination function for Worley method: ", mod)
        end
    else
        print("invalid combination function passed to Worley method: ", err)
    end
end

local function worley(seed, width, height, length, options)
    --local points = generate_points(seed, width, height, options.cellsize, options.mean_points)

    local n = options.n
    local combfunc = options.combfunc
    local graphs = { }

    local Fns = { }

    local freq = 0
    if options.loop then
        freq = options.loops.x
    end

    local ltc = Lattice2:new{
        seed=seed,
        width=width,
        height=height,
        cs=options.cellsize,
        freq=freq,
    }

    for x=0,width-1 do
        for y=0,height-1 do
            Fns[y*width + x] = Fn(ltc, n, x, y, options)
        end
    end

    for i=0,#Fns do
        Fns[i] = utils.clamp(0, 10, combfunc(n, Fns[i]))
    end

    graphs[1] = Fns

    return graphs
end

return {
    worley=worley,
    create_combination=create_combination,
    nth=nth
}