local utils = require("utils")

local gaussian_defs = {
    radius = 5,
    stddev = 3,
    apply_x = true,
    apply_y = true,
}

local function gaussian_dlog(parent, defs)
  local dlog = Dialog {
    title = "Gaussian Blur Options",
    parent = parent
  }
  dlog:number { id = "radius", label = "Radius", decimals=0, text = tostring(defs.radius) }
      :number { id = "stddev", label = "Std. Dev.", decimals=3, text = tostring(defs.stddev) }
      :check  { id= "apply_x", label="Hor. Blur", selected=defs.apply_x }
      :check  { id= "apply_y", label="Vert. Blur", selected=defs.apply_y }
      :button { id = "ok", text = "OK", focus = true }
      :button { id = "cancel", text = "Cancel" }
      :show()

  return dlog.data
end


return {
    dlog = gaussian_dlog,
    defs = gaussian_defs,
}
