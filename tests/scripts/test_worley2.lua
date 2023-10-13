local utils = require("utils")
local worley = require("worley")

local width = 192
local height = 192
local frames = 6
local mopts = {
  cellsize=16,
  mean_points=4, -- average number of points per cell
  n=2,
  use_custom_combination=false,
  clamp=10,
  combination="a[1]",
  distance_func = "Euclidian",
  frames=1,
  movement=10, -- how much a point may move during animation
  locations=1, -- how many times the point locations change
  loop = true,
  loops = {
      x = width, y = height, z = frames
  },
}

local t = utils.timer_start_ms()

local graphs = worley.worley(123, width, height, frames, {
    mean_points = mopts.mean_points,
    n=mopts.n,
    cellsize = mopts.cellsize,
    clamp = mopts.clamp,
    distance_func = mopts.distance_func == "Euclidian" and utils.dist2 or utils.mh_dist2,
    movement = mopts.movement,
    movement_func = utils.lerp,
    combfunc = worley.nth,
    loop = mopts.loop,
    loops = mopts.loops,
})

print(string.format("elapsed total time: %.2f ms", t()))
