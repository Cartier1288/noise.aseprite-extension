app = app -- stfu lsp
Dialog = Dialog
Point = Point
Color = Color
ldarray = ldarray
Worley = Worley

package.path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;" .. package.path
local libnoise = require("libnoise")
print(libnoise.sum(1, 2, 3, 4, 5, 6))
print(libnoise.sum({ 1, 2, 3, 4, 5, 6 }))
print(libnoise.DISFUNCS.EUCLIDIAN)
local arr = ldarray(123);
arr[1] = 0
print(arr[1])
print(#arr)

local worl = Worley{
    width = 192,
    height = 192,
    length = 10,
    mean_points = 4,
    cellsize = 16,
    n=3,
};
arr = worl:compute()
print(arr[1][321])

local perlin = require("perlin")
local voronoi = require("voronoi")
local worley = require("worley")
local uiworley = require("worley-ui")
local uivoronoi = require("voronoi-ui")
local utils = require("utils")

local function get_seed()
    return os.time()
end

-- todo:
-- 1. add preview option
-- 2. add gradient slider for the palette colors that are selected to bias results
--      similar to photoshop, but where sliders determine the cutoff for each
-- 3. actually add voronoi lol


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

local function perlin_dlog(parent, defs)
    local dlog = Dialog{
        title="Perlin Noise Options",
        parent=parent
    }
    dlog:number{ id="cellsize", label="Cell Size [0,\\infin]", text=tostring(defs.cellsize) }
        :check{ id="fixed", label="Fixed Colors", selected=defs.fixed }
        :check{ id="threed", label="3D Noise (Animate)", selected=defs.threed, onclick=function()
            dlog:modify{
                id="frames",
                visible=dlog.data.threed
            }
            dlog:modify{
                id="rate",
                visible=dlog.data.threed
            }
            dlog:modify{
                id="loopz",
                visible=dlog.data.loop and dlog.data.threed
            }
        end }
        :number{ id="frames", label="Frames to Animate", visible=defs.threed, text=tostring(defs.frames) }
        :number{ id="rate", label="Movement Rate", visible=defs.threed, text=tostring(defs.rate) }
        :check{ id="loop", label="Loop / Tile", selected=defs.loop, onclick=function()
            dlog:modify{
                id="loopx",
                visible=dlog.data.loop
            }
            dlog:modify{
                id="loopy",
                visible=dlog.data.loop
            }
            dlog:modify{
                id="loopz",
                visible=dlog.data.loop and dlog.data.threed
            }
        end }
        :check{ id="loopx", label="Loop X", selected=defs.loopx, visible=defs.loop }
        :check{ id="loopy", label="Loop Y", selected=defs.loopy, visible=defs.loop }
        :check{ id="loopz", label="Loop Z", selected=defs.loopz, visible=(defs.loop and defs.threed) }
        :button{ id="ok", text="OK", focus=true }
        :button{ id="cancel", text="Cancel" }
        :show()

    return dlog.data
end

local method_dlog_map = {
    Dots = dots_dlog,
    Perlin = perlin_dlog,
    Voronoi = uivoronoi.dlog,
    Worley = uiworley.dlog
}

local method_default_map = {
    Dots = { use_brush=false, density=0.25 },
    Perlin = {
        cellsize=8, -- size of each grid cell, the intersection of which is where the
                    -- gradient is computed
        fixed=true, -- only use the colors in the given range, otherwise interpolate between them
        threed=false,
        frames=1,
        rate=1,

        loop=false,
        loopx=false,
        loopy=false,
        loopz=false
    },
    Voronoi = uivoronoi.defs,
    Worley = uiworley.defs
}

local noise_defaults = {
    use_active_layer = false,
    lock_alpha = false,
}

local function noise_dlog()

    local dlog = Dialog("Apply Noise")
    local mopts = nil

    local defs = noise_defaults

    dlog:check{ id="use_active_layer", label="Use Active Layer", 
                selected=defs.use_active_layer,
                onclick=function()
                    dlog:modify {
                        id="lock_alpha",
                        visible=dlog.data.use_active_layer
                    }
                end }
        :check{ id="lock_alpha", label="Lock Alpha", 
                visible=defs.use_active_layer, selected=defs.lock_alpha }
        :number{ id="seed", label="Seed", text=tostring(get_seed()), decimals=0 }
        :combobox{ id="method", label="Method",
            option="Dots",
            options={ "Dots", "Perlin", "Voronoi", "Worley" }
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
            if not mopts then
                mopts = method_default_map[dlog.data.method]
            end
            dlog.data.ok = true
            dlog:close()
        end }
        :button{ id="cancel", text="Cancel" }
        :show()

    return { dlog.data, mopts }

end


local function do_noise(opts, mopts)
    math.randomseed(opts.seed)

    local sprite = app.sprite
    if not sprite then
        return app.alert("no active sprite to apply noise to")
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
    local palette = sprite.palettes[1]

    local get_color = function(int)
        return Color(int)
    end
    if(image.colorMode == ColorMode.INDEXED) then
        get_color = function(idx)
            return palette:getColor(idx)
        end
    end

    local width = sprite.width
    local height = sprite.height

    local alphas = {}
    local do_lock_alpha = opts.use_active_layer and opts.lock_alpha
    if do_lock_alpha then
        local bounds = image.bounds
        local left = cel.position.x
        local right = left+bounds.w
        local top = cel.position.y
        local bottom = top+bounds.h

        -- init everything to 0 to begin with
        for x=0,width-1 do
            alphas[x] = { }
            for y=0,height-1 do
                alphas[x][y] = 0
            end
        end

        print(bounds, left, right, top, bottom, width, height)

        local get_alpha = function(int)
            return app.pixelColor.rgbaA(int)
        end
        if(image.colorMode == ColorMode.INDEXED) then
            get_alpha = function(idx)
                if idx == image.spec.transparentColor then
                    return 0
                else
                    return palette:getColor(idx).alpha
                end
            end
        end

        for it in image:pixels() do
            -- the actual image is at least as small as the cel, so assign each of its pixels based on
            -- its bounds and offset from the cel start
            alphas[it.x + left][it.y + top] = get_alpha(it())
        end

    end

    -- get color range
    local color_range = { app.bgColor, app.fgColor }
    if #(app.range.colors) > 1 then
        color_range = { }
        for i = 1,#app.range.colors do
            color_range[i] = palette:getColor(app.range.colors[i])
        end
    end

    local clear_rect = Rectangle{x=0, y=0, width=1, height=1}

    -- add alpha lock as a seperate pass for simplicity
    local function lock_alpha(img)
        if do_lock_alpha then
            for it in img:pixels() do
                local color = get_color(it())
                local alpha = alphas[it.x][it.y]
                color = Color {
                    red=color.red,
                    green=color.green,
                    blue=color.blue,
                    alpha=alpha
                }
                image:drawPixel(it.x, it.y, color)
            end
        end
    end

    -- let closures do the work for me :)
    local function do_dots()
        layer.name = "Dot Noise"

        local brush = app.activeBrush
        if mopts.use_brush and not brush then
            return app.alert("dots.active_brush set but no active brush")
        end

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

        lock_alpha(image)
    end

    local function do_perlin()
        layer.name = "Perlin Noise"

        local frames = mopts.threed and mopts.frames or 1
        local noisef = mopts.threed and perlin.perlin3d or perlin.perlin

        local loop = {
            loopx = utils.id,
            loopy = utils.id,
            loopz = utils.id
        }

        if mopts.loop then
            if mopts.loopx then
                loop.xfrom = 0
                loop.xto = width/mopts.cellsize

                local dxloop = loop.xto - loop.xfrom
                loop.loopx = function(v) return utils.loop(v, loop.xfrom, dxloop) end
            end
            if mopts.loopy then
                loop.yfrom = 0
                loop.yto = height/mopts.cellsize

                local dyloop = loop.yto - loop.yfrom
                loop.loopy = function(v) return utils.loop(v, loop.yfrom, dyloop) end
            end
            if mopts.loopz then
                loop.zfrom = 1
                loop.zto = (frames*mopts.rate)/mopts.cellsize+1

                local dzloop = loop.zto - loop.zfrom
                loop.loopz = function(v) return utils.loop(v, loop.zfrom, dzloop) end
            end
        end

        for z=1,frames do

        -- if we don't already have a frame create it
        if z > #sprite.frames then
            sprite:newFrame(z)
        end

        cel = sprite:newCel(layer, z)
        image = cel.image

        for x=0,width do
            for y=0,height do

                local val = noisef(opts.seed, x/mopts.cellsize, y/mopts.cellsize, (z*mopts.rate)/mopts.cellsize, loop)
                val = val*0.5+0.5 -- normalize

                local color = nil

                if mopts.fixed then
                    color = utils.color_grad_fixed(val, table.unpack(color_range))
                else
                    color = utils.color_grad(val, table.unpack(color_range))
                end

                image:drawPixel(x, y, color)
            end
        end

        lock_alpha(image)
        end
    end

    local function do_voronoi()
        layer.name = "Voronoi Graph"

        local frames = mopts.threed and mopts.frames or 1

        local graphs = voronoi.voronoi(opts.seed, width, height, frames, {
            colors = #color_range,
            points = { mopts.min_points, mopts.max_points },
            distance_func = mopts.distance_func == "Euclidian" and utils.dist2 or utils.mh_dist2,
            relax = mopts.relax,
            relax_steps = mopts.relax_steps,
            movement = mopts.movement,
            locations = mopts.locations,
            loop = mopts.loop
        }, { })

        -- if we don't already have a frame create it
        for z=1,frames do

        if z > #sprite.frames then
            sprite:newFrame(z)
        end

        cel = sprite:newCel(layer, z)
        image = cel.image

        local graph = graphs[z]

        for x=0,width-1 do
            for y=0,height-1 do
                image:drawPixel(x, y, color_range[ graph[y*width + x] ])
            end
        end

        lock_alpha(image)
        end
    end

    local function do_worley()
        layer.name = "Worley Graph"

        local frames = mopts.threed and mopts.frames or 1

        local combfunc = worley.nth

        if mopts.use_custom_combination then
            combfunc = worley.create_combination(mopts.combination)
        end

        local loop = { x = 0, y = 0, z = 0 };
        if mopts.loop then
            loop = {
                x = width / mopts.cellsize,
                y = height / mopts.cellsize,
                z = 0
            }
        end

        --local t = os.clock()

        local graphs = worley.worley(opts.seed, width, height, frames, {
            colors = #color_range,
            mean_points = mopts.mean_points,
            n=mopts.n,
            cellsize = mopts.cellsize,
            clamp = mopts.clamp,
            distance_func = mopts.distance_func == "Euclidian" and utils.dist2 or utils.mh_dist2,
            movement = mopts.movement,
            movement_func = mopts.movement_func,
            locations = mopts.locations,
            combfunc = combfunc,
            loop = mopts.loop,
            loops = loop,
            seed = opts.seed,
        })

        --print(string.format("elapsed time: %.2f\n", os.clock()-t))

        -- if we don't already have a frame create it
        for z=1,frames do

        if z > #sprite.frames then
            sprite:newFrame(z)
        end

        cel = sprite:newCel(layer, z)
        image = cel.image

        local graph = graphs[z]

        for x=0,width-1 do
            for y=0,height-1 do
                local val = graph[y*width + x]
                image:drawPixel(x, y, utils.color_grad(val, table.unpack(color_range)))
            end
        end

        lock_alpha(image)
        end
    end

    local noise_appliers = {
        Dots = do_dots,
        Perlin = do_perlin,
        Voronoi = do_voronoi,
        Worley = do_worley,
    }

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

--[[
return {
  noise_dlog = function() end,
  noise = function() end,
  noise_try = function() end,
}
--]]
