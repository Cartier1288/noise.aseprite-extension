local utils = require("utils")
local movement_funcs = {
    LERP = utils.lerp,
    CERP = utils.cerp,
    smootherstep = utils.smootherstep
}

local worley_defs = {
    cellsize=16,
    mean_points=4, -- average number of points per cell
    n=1,
    use_custom_combination=false,
    combination="a[1]",
    distance_func = "Euclidian",
    clamp = 10, -- distance clamp
    threed=false,
    loop=false,
    loopx=false,
    loopy=false,
    loopz=false,
    frames=1,
    movement=16, -- how much a point may move during animation
    movement_func = "LERP", -- { "LERP", "CERP", "smootherstep"}
}

local function worley_dlog(parent, defs)
    local dlog = Dialog{
        title="Worley Noise Options",
        parent=parent
    }
    dlog:number{ id="cellsize", label="Cell Size (0,\\infin]", text=tostring(defs.cellsize) }
        :number{ id="mean_points", label="Mean Points (Per Cell) (0,\\infin]", text=tostring(defs.mean_points) }
        :number{ id="n", label="n [1,\\infin]", text=tostring(defs.n) }
        :check{ id="use_custom_combination", label="Custom Combination", selected=defs.use_custom_combination,
        onclick=function()
            dlog:modify{ id="combination", visible=dlog.data.use_custom_combination }
        end }
        :entry{ id="combination", label="Combination", visible=defs.use_custom_combination, text=defs.combination }
        :combobox{ id="distance_func", label="Distance Function",
            option=defs.distance_func,
            options={ "Euclidian", "Manhattan" }
        }
        :number{ id="clamp", label="Clamp Distance (0,\\infin]", text=tostring(defs.clamp) }
        :check{ id="threed", label="3D (Animate)", selected=defs.threed, onclick=function()
            dlog:modify{ id="frames", visible=dlog.data.threed }
            dlog:modify{ id="loopz", visible=(dlog.data.threed and dlog.data.loop) }
            dlog:modify{ id="movement", visible=dlog.data.threed }
            dlog:modify{ id="movement_func", visible=dlog.data.threed }
            dlog:modify{ id="locations", visible=dlog.data.threed }
        end }
        :number{ id="frames", label="Frames to Animate", visible=defs.threed, text=tostring(defs.frames) }
        :number{ id="movement", label="Point Movement [0,\\infin]", visible=defs.threed, text=tostring(defs.movement) }
        :combobox{ id="movement_func", label="Movement Function", visible=defs.threed,
            option=defs.movement_func,
            options=utils.get_keys(movement_funcs)
        }
        :check{ id="loop", label="Loop / Tile", selected=defs.loop, onclick=function()
            dlog:modify{ id="loopx", visible=dlog.data.loop }
            dlog:modify{ id="loopy", visible=dlog.data.loop }
            dlog:modify{ id="loopz", visible=dlog.data.loop and dlog.data.threed }
        end }
        :check{ id="loopx", label="Loop X", selected=defs.loopx, visible=defs.loop }
        :check{ id="loopy", label="Loop Y", selected=defs.loopy, visible=defs.loop }
        :check{ id="loopz", label="Loop Z", selected=defs.loopz, visible=(defs.loop and defs.threed) }
        :button{ id="ok", text="OK", focus=true }
        :button{ id="cancel", text="Cancel" }
        :show()

    return dlog.data
end


return {
    dlog = worley_dlog,
    defs = worley_defs,
}