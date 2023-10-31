local utils = require("utils")

local pi2 = 2*math.pi


-- for efficiency, the gradient is stored as a single array of integers where each successive pair
-- is a corresponding gradient/vector
local function gen_grad(seed, size)
    local corners = size

    local grad = {}
    grad[corners*2] = 0 -- pre allocate

    local r

    math.randomseed(seed)

    for i=1,corners*2,2 do
        r = math.random()*pi2
        grad[i] = math.cos(r)
        grad[i+1] = math.sin(r)
    end

    return grad
end

local function gen_grad3d(seed, size)
    local corners = size

    local grad = {}
    grad[corners*3] = 0 -- pre allocate

    local r1,r2,r3

    math.randomseed(seed)

    for i=1,corners*3,3 do
        r1 = math.random()*pi2
        r2 = math.random()*pi2
        r3 = math.random()*pi2
        grad[i] = math.sin(r1)
        grad[i+1] = math.sin(r2)
        grad[i+2] = math.sin(r3)

        local mag = math.sqrt(
            grad[i]*grad[i] +
            grad[i+1]*grad[i+1] +
            grad[i+2]*grad[i+2]
        )
        grad[i] = grad[i] / mag
        grad[i+1] = grad[i+1] / mag
        grad[i+2] = grad[i+2] / mag
    end

    return grad
end

local fixed_grad = gen_grad(tonumber(os.time()), 256*256)
local fixed_grad3d = gen_grad3d(tonumber(os.time()), 256*256)

local function random_grad_fixed(seed, cx, cy)
    math.randomseed(seed*cx, seed*cy)
    local idx = math.floor(math.random()*(#fixed_grad/2))+1
    return { x = fixed_grad[idx], y = fixed_grad[idx+1] }
end

local function random_grad3d_fixed(seed, cx, cy, cz)
    math.randomseed(seed*cx + cz, seed*cy + cz)
    local idx = math.floor(math.random()*(#fixed_grad3d/3))+1
    return { x = fixed_grad3d[idx], y = fixed_grad3d[idx+1], z = fixed_grad3d[idx+2] }
end

local function random_grad_native(seed, cx, cy)
    local w = 64
    local s = w/2

    local a,b = math.tointeger(cx),math.tointeger(cy)
    a = a*3284157443*seed; b = b ~ ((a<<s) | (a >> (w-s)))
    b = b*1911520717*seed; a = a ~ ((b<<s) | (b >> (w-s)))
    a = a*2048419325*seed;

    local r = a*(3.141592653589793 / ~(~0 >> 1))
    return { x = math.cos(r), y = math.sin(r) }
end

local function random_grad_lua(seed, cx, cy)
    math.randomseed(seed * cx, seed * cy)
    local r = math.random()*pi2
    return { x = math.cos(r), y = math.sin(r) }
end


-- requires: random_gradient(cx, cy) == random_gradient(cx, cy) for the same seed
local random_grad = random_grad_native
local random_grad3d = random_grad3d_fixed

-- dot(dist(corner, point), grad)
local function dot_grid_grad(seed, cx, cy, x, y, loop)
    local grad = random_grad(seed, loop.loopx(cx), loop.loopy(cy))

    local dx = x - cx
    local dy = y - cy

    return (dx*grad.x + dy*grad.y)
end

local function dot_grid3d_grad(seed, cx, cy, cz, x, y, z, loop)
    local grad = random_grad3d(seed, loop.loopx(cx), loop.loopy(cy), loop.loopz(cz))

    local dx = x - cx
    local dy = y - cy
    local dz = z - cz

    return (dx*grad.x + dy*grad.y + dz*grad.z)
end

local interpolate = utils.smootherstep

-- for convenience, perlin is given the same signature as perlin3d, the fourth arg is just unused
local function perlin2d(seed, x, y, _, loop)

    -- get the corners for the gradient
    local cx = math.floor(x)
    local cx1 = cx+1
    local cy = math.floor(y)
    local cy1 = cy+1

    -- how far are we into the cell
    local sx = x - cx
    local sy = y - cy

    -- top-left -> top-right
    local n0 = dot_grid_grad(seed, cx, cy, x, y, loop)
    local n1 = dot_grid_grad(seed, cx1, cy, x, y, loop)
    local topdot = interpolate(n0, n1, sx)

    -- bottom-left -> bottom-right
    n0 = dot_grid_grad(seed, cx, cy1, x, y, loop)
    n1 = dot_grid_grad(seed, cx1, cy1, x, y, loop)
    local botdot = interpolate(n0, n1, sx)

    return interpolate(topdot, botdot, sy)
end

local function perlin3d(seed, x, y, z, loop)

    -- get the corners for the gradient
    local cx = math.floor(x)
    local cx1 = cx+1
    local cy = math.floor(y)
    local cy1 = cy+1
    local cz = math.floor(z)
    local cz1 = cz+1

    -- how far are we into the cell
    local sx = x - cx
    local sy = y - cy
    local sz = z - cz

    -- top-left
    local n0 = dot_grid3d_grad(seed, cx, cy, cz, x, y, z, loop)
    -- top-right
    local n1 = dot_grid3d_grad(seed, cx1, cy, cz, x, y, z, loop)
    -- top-left back
    local n2 = dot_grid3d_grad(seed, cx, cy, cz1, x, y, z, loop)
    -- top-right back
    local n3 = dot_grid3d_grad(seed, cx1, cy, cz1, x, y, z, loop)
    -- top-left -> top-right
    local topdot = interpolate(n0, n1, sx)
    local topbackdot = interpolate(n2, n3, sx)
    topdot = interpolate(topdot, topbackdot, sz)

    -- bot-left
    n0 = dot_grid3d_grad(seed, cx, cy1, cz, x, y, z, loop)
    -- bot-right
    n1 = dot_grid3d_grad(seed, cx1, cy1, cz, x, y, z, loop)
    -- bot-left back
    n2 = dot_grid3d_grad(seed, cx, cy1, cz1, x, y, z, loop)
    -- bot-right back
    n3 = dot_grid3d_grad(seed, cx1, cy1, cz1, x, y, z, loop)
    -- bot-left -> bot-right
    local botdot = interpolate(n0, n1, sx)
    local botbackdot = interpolate(n2, n3, sx)
    botdot = interpolate(botdot, botbackdot, sz)

    return interpolate(topdot, botdot, sy)
end

-- opts: {
--      seed: int,
--      dimensions: int in { 2, 3 },
--      movement: double,
--      cellsize: double,
--      width: int,
--      height: int,
--      frames: int,
--      octaves: int,
--      loop: {
--          loopx: double (*loopf)(double),
--          loopy: double (*loopf)(double),
--          loopz: double (*loopf)(double),
--      }
-- }
local function perlin(opts)
    local noisef = perlin2d

    if opts.dimensions == 3 then
        noisef = perlin3d
    end

    local cs = opts.cellsize

    -- generate looping functions for each octive as necessary
    local loops = { }
    local loopx = opts.loop.loopx
    local loopy = opts.loop.loopy
    local loopz = opts.loop.loopz
    for i=1,opts.octaves do
        local freq = 2^(i-1)
        loops[i] = {
            loopx = (loopx and function(val) return utils.loop(val, 0, freq*loopx) end) or utils.id,
            loopy = (loopy and function(val) return utils.loop(val, 0, freq*loopy) end) or utils.id,
            loopz = (loopz and function(val) return utils.loop(val, 0, freq*loopz) end) or utils.id,
        }
    end

    local graphs = { }

    -- calculate final sum of amplitudes S = \sum_{i=0}{octaves}{(1/2)^i} = 2 - (1/2)^{octaves}
    local total_amplitude = 2 - 0.5^(opts.octaves-1)

    local zjump = (1/opts.frames) * opts.movement

    for frame=1,opts.frames do

    -- movement actually gets scaled back to match looping, so that there aren't two frames at the
    -- same z position, this is fine as long as movement doesn't need to be PRECISE
    local z = (frame-1) * zjump
    local adj_z = z

    graphs[frame] = { }; local graph = graphs[frame]
    graph[opts.width * opts.height] = 0

    for y=0, opts.height-1 do
        local scanned = y * opts.width
        local adj_y = y / cs

        for x=0,opts.width-1 do
            local weight = 1

            local val = 0

            local adj_x = x / cs

            for i=1,opts.octaves do
                val = val + weight*noisef(
                    opts.seed,
                    adj_x / weight,
                    adj_y / weight,
                    adj_z / weight,
                    loops[i]
                )
                weight = weight * 0.5
            end

            val = val / total_amplitude
            graph[scanned + x] = val
        end
    end

    end

    return graphs
end

local function paint_perlin(sp, opts, mopts)
    sp.layer.name = "Perlin Noise"

    local frames = mopts.threed and mopts.frames or 1

    local graphs = perlin {
        seed = opts.seed,
        dimensions = mopts.threed and 3 or 2,
        movement = mopts.movement,
        cellsize = mopts.cellsize,
        width = sp.width,
        height = sp.height,
        frames = frames,
        octaves = mopts.octaves,
        loop = {
            loopx = mopts.loop and mopts.loopx and sp.width / mopts.cellsize,
            loopy = mopts.loop and mopts.loopy and sp.height / mopts.cellsize,
            loopz = mopts.loop and mopts.loopz and mopts.movement,
        },
    }

    local color = nil

    if mopts.scale_range then
        for g=1, #graphs do
            graphs[g] = utils.scale(graphs[g], 0, -1, 1)
        end
    end

    for pixel in sp:animate(frames) do
          local val = graphs[pixel.frame][pixel.idx]
          val = val * 0.5 + 0.5   -- normalize

          if mopts.fixed then
            color = utils.color_grad_fixed(val, table.unpack(sp.color_range))
          else
            color = utils.color_grad(val, table.unpack(sp.color_range))
          end

          pixel:put(color)
    end
end

return {
    perlin2d=perlin2d,
    perlin3d=perlin3d,
    perlin=perlin,
    paint_perlin=paint_perlin
}