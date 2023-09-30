
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

local function color_grad(t, ...)
    local arg={...}

    -- app.alert("Length of args: " .. tostring(#arg))
    -- app.alert("t: " .. tostring(t))

    -- remember indexing starts from 1 :) :) :)
    local from = math.floor(t * (#arg-1))+1
    local to = from+1

    -- app.alert("from: " .. tostring(from) .. ", to: " .. tostring(to))

    -- get adjusted t between the two color indices
    local adj_t = (t*(#arg-1)) - from

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

return {
    round=round,
    lerp=lerp,
    cerp=cerp,
    color_grad=color_grad,
    color_grad_fixed=color_grad_fixed,
    loop=loop,
    id=id,
    dump=dump
}