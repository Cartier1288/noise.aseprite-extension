local voronoi = require("voronoi")
local utils = require("utils")

local seed = app.params.seed and tonumber(app.params.seed) or 314159
local width = 64
local height = 64
local frames = 16

local colors = 8
local points = { 32, 32 }
local distance_func = utils.dist2
local relax = true
local relax_steps = 3
local movement = 8
local locations = 2
local loop = true

local graphs = voronoi.voronoi(seed, width, height, frames, {
    colors = colors,
    points = points,
    distance_func = distance_func,
    relax = relax,
    relax_steps = relax_steps,
    movement = movement,
    locations = locations,
    loop = loop
}, {})