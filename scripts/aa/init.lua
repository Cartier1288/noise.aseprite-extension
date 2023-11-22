local utils = require("utils")
local smaa = require("aa.smaa")
local gaussian = require("aa.gaussian")
local uiaa = require("aa.aa-ui")

return utils.cat(
    smaa,
    gaussian,
    uiaa
)