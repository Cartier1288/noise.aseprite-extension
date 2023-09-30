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
local function perlin(seed, x, y, _, loop)

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

return {
    perlin=perlin,
    perlin3d=perlin3d
}