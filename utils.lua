
local function round(v)
    return math.floor(v+0.5)
end

-- linear interpolate
local function lerp(p1, p2, t)
    return (p2 - p1) * t + p1;
end

-- cubic interpolate
local function cerp(p1, p2, t)
    return (p2 - p1) * (3.0 - t*2.0) * t*t + p1;
end

local function smootherstep(p1, p2, t)
    return (p2 - p1) * ((t * (t*6 - 15) + 10) * t*t*t) + p1
end

local function color_grad(t, ...)
    local arg={...}

    -- app.alert("Length of args: " .. tostring(#arg))
    -- app.alert("t: " .. tostring(t))

    -- remember indexing starts from 1 :) :) :)
    local from = math.floor(t * (#arg-1))+1
    local to = from+1

    -- app.alert("from: " .. tostring(from) .. ", to: " .. tostring(to))

    -- get adjusted t between the two color indices
    local adj_t = (t*(#arg-1)) - (from-1) -- adjust for +1 index :)

    from = arg[from]
    to = arg[to]

    return Color {
        r = lerp(from.red, to.red, adj_t),
        g = lerp(from.green, to.green, adj_t),
        b = lerp(from.blue, to.blue, adj_t),
        a = lerp(from.alpha, to.alpha, adj_t)
    }
end

local function color_grad_fixed(t, ...)
    local arg={...}

    -- remember indexing starts from 1 :) :) :)
    local cidx = round(t * (#arg-1))+1

    return arg[cidx]
end

local function loop(v, from, diff)
    return ((v - from) % diff) + from
end

local function id(v)
    return v
end

-- stolen from: https://stackoverflow.com/a/27028488
local function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end

local function set_default(table, defs)
    local mt = { __index = function(key) return defs[key] end }
    setmetatable(table, mt)
end

local function dist2(x1, x2, y1, y2)
    local d1 = x1-y1
    local d2 = x2-y2
    return math.sqrt(d1*d1 + d2*d2)
end

-- Manhattan distance
local function mh_dist2(x1, x2, y1, y2)
    local d1 = x1-y1
    local d2 = x2-y2
    return math.abs(d1) + math.abs(d2)
end

local function centroid(points)
    local x, y = 0, 0

    for p=1,#points do
        x = x + points[p][1]
        y = y + points[p][2]
    end

    x, y = x / #points, y / #points

    return { x, y }
end

return {
    round=round,
    lerp=lerp,
    cerp=cerp,
    smootherstep=smootherstep,
    color_grad=color_grad,
    color_grad_fixed=color_grad_fixed,
    loop=loop,
    id=id,
    dump=dump,
    set_default=set_default,
    dist2=dist2,
    mh_dist2=mh_dist2,
    centroid=centroid
}