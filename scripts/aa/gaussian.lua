local utils = require("utils")
local ConvMatrix = require("convolution").ConvMatrix

-- pre-compute Gaussian convolution matrices

local function get_gauss_conv(width, height, mean, stddev)
    local conv = ConvMatrix:new(width, height)

    for y=0,conv.height-1 do
        for x=0,conv.width-1 do
            conv:set(x, y,
                utils.pgauss(x + conv.xstart, mean, stddev) *
                utils.pgauss(y + conv.ystart, mean, stddev)
            )
        end
    end

    -- discretized Gaussian will no longer sum to 1, make it do so to avoid darkening the image
    conv:normalize()

    return conv
end

-- opts: {
--  radius: the radius of the kernel to use for convolution
--  stddev: the standard deviation of the Gaussian function
--  apply_x: blur horizontally
--  apply_y: blur vertically
-- }
local function gaussian(buffer, opts)
    -- seperable property: n x n conv same as n x 1, 1 x n conv matrices applied separately
    local xconv = get_gauss_conv(opts.radius, 1, 0--[[or 255]], opts.stddev)
    local yconv = get_gauss_conv(1, opts.radius, 0--[[or 255]], opts.stddev)

    local convs = { }
    if opts.apply_x then table.insert(convs, xconv) end
    if opts.apply_y then table.insert(convs, yconv) end

    local bbuffer

    -- todo: move this directly into ConvMatrix, have some option that lets you specify whether it
    -- is separable
    for _,conv in ipairs(convs) do
        bbuffer = buffer:clone()
        for el in bbuffer:iterate(0) do
            el:put(0, conv:apply(buffer, el.x, el.y, 0))
            el:put(1, conv:apply(buffer, el.x, el.y, 1))
            el:put(2, conv:apply(buffer, el.x, el.y, 2))
            el:put(3, conv:apply(buffer, el.x, el.y, 3))
        end
        buffer = bbuffer
    end

    return bbuffer
end

-- Gaussian blur with a low std. dev. can serve as an antialiasing filter
local function paint_gaussian(sp, opts, mopts)
    local buffer

    local gopts = {
        radius = mopts.radius,
        stddev = mopts.stddev,
        apply_x = mopts.apply_x,
        apply_y = mopts.apply_y,
    }

    local function apply_gauss()
        return 
    end

    local frames = { app.frame.frameNumber or 1 }
    -- note a value of nil to paint_over just uses all active frames
    if opts.all_frames then frames = nil end

    for finfo in sp:paint_over(frames) do
        buffer = sp:to_buffer()
        buffer = gaussian(buffer, gopts)
        sp:from_buffer(buffer)
    end
end

return {
    gaussian = gaussian,
    paint_gaussian = paint_gaussian,
    get_gauss_conv = get_gauss_conv,
}