local utils = require("utils")

local SMAA_defs = {
}

local function SMAA_dlog(parent, defs)
  local dlog = Dialog {
    title = "SMAA Options",
    parent = parent
  }
  dlog:label { id = "label", label = "No parameters (yet)" }
      :button { id = "ok", text = "OK", focus = true }
      :button { id = "cancel", text = "Cancel" }
      :show()

  return dlog.data
end


return {
    dlog = SMAA_dlog,
    defs = SMAA_defs,
}
