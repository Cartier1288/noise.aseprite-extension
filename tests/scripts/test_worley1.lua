local libnoise = require("libnoise")
local utils = require("utils")

local width = 192
local height = 192
local frames = 12
local mopts = {
    cellsize=16,
    mean_points=4, -- average number of points per cell
    n=2,
    use_custom_combination=false,
    combination="a[1]",
    distance_func = "Euclidian",
    frames=1,
    movement=10, -- how much a point may move during animation
    locations=1, -- how many times the point locations change
    loop = {
        x = 192, y = 192, z = 12
    },
}

local t = utils.timer_start_ms()

local W = Worley {
    seed = 123,
    width = width,
    height = height,
    length = frames,
    mean_points = mopts.mean_points,
    n=mopts.n,
    cellsize = mopts.cellsize,
    distance_func = libnoise.DISFUNCS[mopts.distance_func],
    movement = mopts.movement,
    movement_func = libnoise.ERPFUNCS[mopts.movement_func],
    loops = mopts.loop,
}

print(W)

print(string.format("elapsed init. time: %.2f ms\n", t()))

local graphs = W:compute()

print(string.format("elapsed total time: %.2f ms\n", t()))
