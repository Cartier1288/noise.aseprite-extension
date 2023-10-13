local libnoise = require("libnoise")
local utils = require("utils")

local t = utils.timer_start_ms()

local size = 30000000

local arr = ldarray(size)

print(string.format("elapsed init. time: %.2f ms\n", t()))

for i=1,#arr do
    arr[i] = i * i
end

print(arr[size])

print(string.format("elapsed total time: %.2f ms\n", t()))
