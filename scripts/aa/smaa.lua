local utils = require("utils")
local libnoise = utils.try_load_dlib("libnoise")

-- antialiasing filters

local SMAA_THRESHOLD = 0.1

local threshold = { SMAA_THRESHOLD, SMAA_THRESHOLD }

local function abs_diff3(a, b)
    return {
        math.abs(a[0] - b[0]),
        math.abs(a[1] - b[1]),
        math.abs(a[2] - b[2])
    }
end

local function detect_edge_color(x, y, offset, buffer)
    
    local delta = { x = 0, y = 0, z = 0, w = 0 }

    local C = buffer:get_vec(x, y, 3)
    local Cleft = buffer:get_vec(offset[0], offset[1], 3)
    local Ctop = buffer:get_vec(offset[2], offset[3], 3)
    local Cright = buffer:get_vec(offset[2], offset[3], 3)

    local t = abs_diff3(C, Cleft)
    delta.x = math.max(math.max(t[0], t[1]), t[2])


end

local function lua_SMAA(width, height, buffer, opts)
    return { 0x1DEADB0B }
end

local SMAA = libnoise and libnoise.SMAA or lua_SMAA

-- reference paper: https://www.iryoku.com/smaa/
local function paint_SMAA(sp, opts, mopts)
    local frames = { app.frame.frameNumber or 1 }
    -- note a value of nil to paint_over just uses all active frames
    if opts.all_frames then frames = nil end

    for finfo in sp:paint_over(frames) do
        local original = sp:to_buffer()
        local arr = SMAA(sp.width, sp.height, original.elements, {})
        sp:from_arr(arr)
    end
end

return {
    SMAA = libnoise and libnoise.SMAA or SMAA,
    paint_SMAA = paint_SMAA,
}