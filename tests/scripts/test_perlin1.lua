local perlin = require("perlin")

local dimensions = 3
local movement = 2
local cellsize = 256
local width = 32
local height = 32
local frames = 16
local octaves = 7
local loop = {
    loopx = width / cellsize,
    loopy = height / cellsize,
    loopz = movement,
}

perlin.perlin{
    seed = app.params.seed and tonumber(app.params.seed) or 314159,
    dimensions = dimensions,
    movement = movement,
    cellsize = cellsize,
    width = width,
    height = height,
    frames = frames,
    octaves = octaves,
    loop = loop,
}
