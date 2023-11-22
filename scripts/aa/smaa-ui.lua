local utils = require("utils")

local SMAA_defs = {
    radius = 3,
}

local function SMAA_dlog(parent, defs)
  local dlog = Dialog {
    title = "SMAA Options",
    parent = parent
  }
  dlog:number { id = "radius", label = "Radius", decimals=0, text = tostring(defs.radius) }
      :button { id = "ok", text = "OK", focus = true }
      :button { id = "cancel", text = "Cancel" }
      :show()

  return dlog.data
end


return {
    dlog = SMAA_dlog,
    defs = SMAA_defs,
}
