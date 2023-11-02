app = app -- stfu lsp
Dialog = Dialog
Point = Point
Color = Color
ColorMode = ColorMode
ldarray = ldarray
Worley = Worley


-- for convenience, also add the scripts folder directly to the path to avoid having to write
-- scripts.[...] every time
local pwd = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]
package.path = pwd .. "?.lua;" .. package.path
package.path = pwd .. "?/init.lua;" .. package.path

local utils = require("utils")
local SpritePainter = require("sprite-painter").SpritePainter
local Gradient = require("gradient")

local dots = require("dots")
local perlin = require("perlin")
local voronoi = require("voronoi")
local worley = require("worley")
local uiperlin = require("perlin-ui")
local uivoronoi = require("voronoi-ui")
local uiworley = require("worley-ui")

local function get_seed()
  return os.time()
end

-- todo:
-- 1. add preview option
-- 2. add gradient slider for the palette colors that are selected to bias results
--      similar to photoshop, but where sliders determine the cutoff for each


local function dots_dlog(parent, defs)
  local dlog = Dialog {
        title = "Dot Noise Options",
        parent = parent
      }
      :check { id = "use_brush", label = "Use Brush", selected = defs.use_brush }
      :number { id = "density", label = "Density [0,1]", decimals=3, text = tostring(defs.density) }
      :button { id = "ok", text = "OK", focus = true }
      :button { id = "cancel", text = "Cancel" }
      :show()

  return dlog.data
end

local method_dlog_map = {
  Dots = dots_dlog,
  Perlin = uiperlin.dlog,
  Voronoi = uivoronoi.dlog,
  Worley = uiworley.dlog
}

local method_default_map = {
  Dots = { use_brush = false, density = 0.25 },
  Perlin = uiperlin.defs,
  Voronoi = uivoronoi.defs,
  Worley = uiworley.defs
}

local noise_defaults = {
  use_active_layer = false,
  lock_alpha = false,
}

local function noise_dlog(prev_opts, prev_mopts)
  local dlog = Dialog("Apply Noise")
  local mopts = nil

  local defs = noise_defaults

  local cdata = utils.DialogCustomData:new(dlog)

  dlog:check { id = "use_active_layer", label = "Use Active Layer",
    selected = defs.use_active_layer,
    onclick = function()
      dlog:modify {
        id = "lock_alpha",
        visible = dlog.data.use_active_layer
      }
    end }
      :check { id = "lock_alpha", label = "Lock Alpha",
        visible = defs.use_active_layer, selected = defs.lock_alpha }
      :number { id = "seed", label = "Seed", text = tostring(get_seed()), decimals = 0 }
      :combobox { id = "method", label = "Method",
        option = "Dots",
        options = { "Dots", "Perlin", "Voronoi", "Worley" }
      }
      :button { id = "pick_methodoptions", text = "Method Options", onclick = function()
        local cmethod = dlog.data.method
        local method_opts = method_dlog_map[cmethod](dlog, mopts or method_default_map[cmethod])
        if method_opts.ok then
          mopts = method_opts
        end
      end }

      utils.Dialog_gradient(dlog, cdata, {
        id="colors",
        label="Color Picker",
        mode="sort",
        colors=utils.get_selected_colors(app.sprite)
      })

      dlog
      :newrow()
      :button { id = "ok", text = "OK", focus = true, onclick = function()
        if not mopts then
          mopts = method_default_map[dlog.data.method]
        end
        dlog.data.ok = true
        dlog:close()
      end }
      :button { id = "cancel", text = "Cancel" }
      :show()

  local opts = utils.cat(dlog.data)
  local cgrad_data = cdata:get("colors")
  opts.colors = cgrad_data.colors
  opts.grad = Gradient:new(cgrad_data.colors, cgrad_data.cutoffs, { })

  return { opts, mopts }
end


local function do_noise(opts, mopts)
  math.randomseed(opts.seed)

  local ok, sp = pcall(function() return SpritePainter:new(opts) end)
  if not ok then return end

  local noise_appliers = {
    Dots = function() dots.paint_dots(sp, opts, mopts) end,
    Perlin = function() perlin.paint_perlin(sp, opts, mopts) end,
    Voronoi = function() voronoi.paint_voronoi(sp, opts, mopts) end,
    Worley = function() worley.paint_worley(sp, opts, mopts) end,
  }

  noise_appliers[opts.method](opts, mopts)
end


local function noise_try(prefs)
  local lc = prefs.last_command

  local sprite = app.activeSprite
  if not sprite then
    return app.alert("no active sprite to apply noise to")
  end

  local dlog_options, mopts = table.unpack(noise_dlog(
    lc and lc.opts,
    lc and lc.mopts
  ))

  -- make sure the user actually confirmed the script application in the dialog
  if dlog_options.ok then

    app.transaction(
      "Noise",
      function()
        do_noise(dlog_options, mopts)
      end
    )
    app.refresh()

    return dlog_options, mopts
  end

  return lc and lc.opts, lc and lc.mopts
end

return {
  noise_dlog = noise_dlog,
  noise = function(opts, mopts)
    app.transaction("Noise", function() do_noise(opts, mopts) end)
    app.refresh()
  end,
  noise_try = noise_try,
  get_seed = get_seed,
}