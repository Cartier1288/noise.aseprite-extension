local worley_defs = {
    cellsize=32,
    mean_points=4, -- average number of points per cell
    n=1,
    combination="1,",
    distance_func = "Euclidian",
    threed=false,
    loop=false,
    frames=1,
    movement=10, -- how much a point may move during animation
    locations=1, -- how many times the point locations change
}

local function worley_dlog(parent, defs)
    local dlog = Dialog{
        title="Worley Noise Options",
        parent=parent
    }
    dlog:number{ id="cellsize", label="Cell Size (0,\\infin]", text=tostring(defs.cellsize) }
        :number{ id="mean_points", label="Mean Points (Per Cell) (0,\\infin]", text=tostring(defs.mean_points) }
        :number{ id="n", label="n [1,\\infin]", text=tostring(defs.n) }
        :combobox{ id="distance_func", label="Distance Function",
            option=defs.distance_func,
            options={ "Euclidian", "Manhattan" }
        }
        :check{ id="threed", label="3D (Animate)", selected=defs.threed, onclick=function()
            dlog:modify{ id="frames", visible=dlog.data.threed }
            dlog:modify{ id="loop", visible=dlog.data.threed }
            dlog:modify{ id="movement", visible=dlog.data.threed }
            dlog:modify{ id="locations", visible=dlog.data.threed }
        end }
        :number{ id="frames", label="Frames to Animate", visible=defs.threed, text=tostring(defs.frames) }
        :check{ id="loop", label="Loop Movement", visible=defs.threed, selected=defs.loop }
        :number{ id="movement", label="Point Movement [0,\\infin]", visible=defs.threed, text=tostring(defs.movement) }
        :number{ id="locations", label="Locations [1,\\infin]", visible=defs.threed, text=tostring(defs.locations) }
        :button{ id="ok", text="OK", focus=true }
        :button{ id="cancel", text="Cancel" }
        :show()

    return dlog.data
end


return {
    dlog = worley_dlog,
    defs = worley_defs,
}