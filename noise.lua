app = app -- stfu lsp
Dialog = Dialog
Point = Point

local function get_seed()
    return os.time()
end


local function dots_dlog(parent, defs)
    local dlog = Dialog{
        title="Dot Noise Options",
        parent=parent
    }
    :check{ id="use_brush", label="Use Brush", selected=defs.use_brush }
    :number{ id="density", label="Density [0,1]", text=tostring(defs.density) }
    :button{ id="ok", text="OK", focus=true }
    :button{ id="cancel", text="Cancel" }
    :show()

    return dlog.data
end

local method_dlog_map = {
    Dots = dots_dlog,
    Perlin = dots_dlog,
    Voronoi = dots_dlog,
}

local method_default_map = {
    Dots = { use_brush=false, density=0.25 },
    Perlin = { },
    Voronoi = { },
}

local function noise_dlog()

    local def_pick_seed = true

    local dlog = Dialog("Apply Noise")
    local mopts = nil

    -- todo: add animate option, to apply random over multiple cels

    dlog:check{ id="use_active_layer", label="Use Active Layer", selected=false }
        :number{ id="seed", label="Seed", text=tostring(get_seed()), decimals=0 }
        :combobox{ id="method", label="Method",
            option="Dots",
            options={ "Dots", "Perlin", "Voronoi" }
        }
        :button{ id="pick_methodoptions", text="Method Options", onclick=function()
            local cmethod = dlog.data.method
            local method_opts = method_dlog_map[cmethod](dlog, method_default_map[cmethod])
            if method_opts.ok then
                mopts = method_opts
            end
        end}
        :newrow()
        :button{ id="ok", text="OK", focus=true, onclick=function()
            if not dlog.data.method_opts then
                mopts = method_default_map[dlog.data.method]
            end
            dlog.data.ok = true
            dlog:close()
        end }
        :button{ id="cancel", text="Cancel" }
        :show()

    return { dlog.data, mopts }

end

local function do_dots(opts, mopts)
    local sprite = app.sprite
    if not sprite then
        return app.alert("no active sprite to apply noise to")
    end

    local brush = app.activeBrush
    if mopts.use_brush and not brush then
        return app.alert("dots.active_brush set but no active brush")
    end

    local layer = nil
    local cel = nil
    if opts.use_active_layer then
        layer = app.layer
        cel = app.cel
        if not layer or not cel then
            return app.alert("opts.use_active_layer set but no active layer")
        end
    else
        layer = sprite:newLayer()
        cel = sprite:newCel(layer, 1)
    end

    local image = cel.image

    layer.name = "Dot Noise"

    local width = sprite.width
    local height = sprite.height

    for x=0,width do
        for y=0,height do

            local r = math.random()
            if r < mopts.density then
                
                if mopts.use_brush then
                    local pt = Point(x,y)
                    app.useTool {
                        tool = "pencil",
                        color = app.fgColor,
                        brush = brush,
                        points = { pt },
                        cel = cel,
                        layer = layer
                    }
                else 
                    image:drawPixel(x, y, app.fgColor)
                end

            end
        end

    end
end

local function do_perlin(opts, mopts)
end

local function do_voronoi(opts, mopts)
end

local noise_appliers = {
    Dots = do_dots,
    Perlin = do_perlin,
    Voronoi = do_voronoi
}

local function do_noise(opts, mopts)
    math.randomseed(opts.seed)
    noise_appliers[opts.method](opts, mopts)
end


local function noise_try()
    local dlog_options, mopts = table.unpack(noise_dlog())

    local sprite = app.activeSprite
    if not sprite then
        return app.alert("no active sprite to apply noise to")
    end

    -- make sure the user actually confirmed the script application in the dialog
    if dlog_options.ok then
        app.transaction(
            "Noise",
            function()
                do_noise(dlog_options, mopts)
            end
        )
        app.refresh()
    end
end

return {
    noise_dlog = noise_dlog,
    noise = function()
        app.transaction("Noise", do_noise)
    end,
    noise_try = noise_try
}