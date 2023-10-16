
local utils = require("utils")

local movement_funcs = {
    LERP = utils.lerp,
    CERP = utils.cerp,
    Smootherstep = utils.smootherstep
}

local voronoi_defs = {
    min_points = 20,
    max_points = 25,
    --distribution = "RANDOM", -- one of: { "RANDOM", "CELLS" }
    distance_func = "Euclidian",
    relax = true,
    relax_steps = 5,
    threed=false,
    loop=false,
    frames=1,
    movement=10, -- how much a point may move during animation
    movement_func = "LERP", -- { "LERP", "CERP", "Smootherstep"}
    locations=1, -- how many times the point locations change
}

local function voronoi_dlog(parent, defs)
    local dlog = Dialog{
        title="Voronoi Noise Options",
        parent=parent
    }
    dlog:number{ id="min_points", label="Min Points [1,\\infin]", text=tostring(defs.min_points) }
        :number{ id="max_points", label="Max Points [Min Points,\\infin]", text=tostring(defs.max_points) }
        :combobox{ id="distance_func", label="Distance Function",
            option=defs.distance_func,
            options={ "Euclidian", "Manhattan" }
        }
        :check{ id="relax", label="Relax Points", selected=defs.relax, onclick=function()
            dlog:modify {
                id="relax_steps",
                visible=dlog.data.relax
            }
        end }
        :number{ id="relax_steps", label="Relax Steps [0,\\infin]", text=tostring(defs.relax_steps) }
        :check{ id="threed", label="3D (Animate)", selected=defs.threed, onclick=function()
            dlog:modify{ id="frames", visible=dlog.data.threed }
            dlog:modify{ id="loop", visible=dlog.data.threed }
            dlog:modify{ id="movement", visible=dlog.data.threed }
            dlog:modify{ id="movement_func", visible=dlog.data.threed }
            dlog:modify{ id="locations", visible=dlog.data.threed }
        end }
        :number{ id="frames", label="Frames to Animate", visible=defs.threed, text=tostring(defs.frames) }
        :check{ id="loop", label="Loop Movement", visible=defs.threed, selected=defs.loop }
        :number{ id="movement", label="Point Movement [0,\\infin]", visible=defs.threed, text=tostring(defs.movement) }
        :combobox{ id="movement_func", label="Movement Function", visible=defs.threed,
            option=defs.movement_func,
            options=utils.get_keys(movement_funcs)
        }
        :number{ id="locations", label="Locations [1,\\infin]", visible=defs.threed, text=tostring(defs.locations) }
        :button{ id="ok", text="OK", focus=true }
        :button{ id="cancel", text="Cancel" }
        :show()

    dlog.data.movement_func = movement_funcs[dlog.data.movement_func]

    return dlog.data
end

return {
    dlog = voronoi_dlog,
    defs = voronoi_defs,
}