local utils = require("utils")

-- requires: random_gradient(cx, cy) == random_gradient(cx, cy) for the same seed
local function random_grad(seed, cx, cy)
    local w = 64
    local s = w/2

    local a,b = cx,cy
    a = a*3284157443*seed; b = b ~ ((a<<s) | (a >> (w-s)))
    b = b*1911520717*seed; a = a ~ ((b<<s) | (b >> (w-s)))
    a = a*2048419325*seed;

    local r = a*(3.141592653589793 / ~(~0 >> 1))
    return { x = math.cos(r), y = math.sin(r)}
end

-- dot(dist(corner, point), grad)
local function dot_grid_grad(seed, cx, cy, x, y)
    local grad = random_grad(seed, cx, cy)

    local dx = x - cx
    local dy = y - cy

    return (dx*grad.x + dy*grad.y)
end

local function perlin(seed, x, y)
    -- get the corners for the gradient
    local cx = math.floor(x)
    local cx1 = cx+1
    local cy = math.floor(y)
    local cy1 = cy+1

    -- how far are we into the cell
    local sx = x - cx
    local sy = y - cy

    -- top-left -> top-right
    local n0 = dot_grid_grad(seed, cx, cy, x, y)
    local n1 = dot_grid_grad(seed, cx1, cy, x, y)
    local topdot = utils.lerp(n0, n1, sx)

    -- bottom-left -> bottom-right
    n0 = dot_grid_grad(seed, cx, cy1, x, y)
    n1 = dot_grid_grad(seed, cx1, cy1, x, y)
    local botdot = utils.lerp(n0, n1, sx)

    return utils.lerp(topdot, botdot, sy)
end

return perlin