local utils = require("utils")

local movement_funcs = {
    LERP = utils.lerp,
    CERP = utils.cerp,
    smootherstep = utils.smootherstep
}

local perlin_defs = {
    cellsize = 8,   -- size of each grid cell, the intersection of which is where the
                    -- gradient is computed
    fixed = true,   -- only use the colors in the given range, otherwise interpolate between them
    threed = false,
    frames = 1,
    movement = 1, -- movement over the full animation (in cellsizes)
    octaves = 1, -- iterations of noise function to add "detail" to the noise at an exponentially
                 -- decreasing scale

    scale_range = false, -- should the output range be scaled to its absolute min and absolute max
                        -- perlin noise very rarely reaches -1 or 1, so this will take the outputted
                        -- min and max and stretch it between those

    loop = false,
    loopx = false,
    loopy = false,
    loopz = false
}

local function perlin_dlog(parent, defs)
  local dlog = Dialog {
    title = "Perlin Noise Options",
    parent = parent
  }
  dlog:number { id = "cellsize", label = "Cell Size [0,\\infin]", decimals=3, 
                text = tostring(defs.cellsize) }
      :number { id = "octaves", label = "Octaves", decimals=0, text = tostring(defs.octaves) }
      :check { id = "scale_range", label = "Scale Range", selected = defs.scale_range }
      :check { id = "fixed", label = "Fixed Colors", selected = defs.fixed }
      :check { id = "threed", label = "3D Noise (Animate)", selected = defs.threed, onclick = function()
        dlog:modify {
          id = "frames",
          visible = dlog.data.threed
        }
        dlog:modify {
          id = "movement",
          visible = dlog.data.threed
        }
        dlog:modify {
          id = "loopz",
          visible = dlog.data.loop and dlog.data.threed
        }
      end }
      :number { id = "frames", label = "Frames to Animate", visible = defs.threed, text = tostring(defs.frames) }
      :number { id = "movement", label = "Movement (In Cellsizes)", visible = defs.threed, decimals=3,
                text = tostring(defs.movement) }
      :check { id = "loop", label = "Loop / Tile", selected = defs.loop, onclick = function()
        dlog:modify {
          id = "loopx",
          visible = dlog.data.loop
        }
        dlog:modify {
          id = "loopy",
          visible = dlog.data.loop
        }
        dlog:modify {
          id = "loopz",
          visible = dlog.data.loop and dlog.data.threed
        }
      end }
      :check { id = "loopx", label = "Loop X", selected = defs.loopx, visible = defs.loop }
      :check { id = "loopy", label = "Loop Y", selected = defs.loopy, visible = defs.loop }
      :check { id = "loopz", label = "Loop Z", selected = defs.loopz, visible = (defs.loop and defs.threed) }
      :button { id = "ok", text = "OK", focus = true }
      :button { id = "cancel", text = "Cancel" }
      :show()

  return dlog.data
end


return {
    dlog = perlin_dlog,
    defs = perlin_defs,
}
