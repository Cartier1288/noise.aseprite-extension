local utils = require("utils")
local SpritePainter = require("sprite-painter").SpritePainter

local gaussian = require("aa.gaussian")
local uigaussian = require("aa.gaussian-ui")

local smaa = require("aa.smaa")
local uismaa = require("aa.smaa-ui")

local method_dlog_map = { }
local method_default_map = { }
local aa_methods = { }

local function AddMethod(name, ui, method)
    method_dlog_map[name] = ui.dlog
    method_default_map[name] = ui.defs
    aa_methods[name] = function(sp, opts, mopts) method(sp, opts, mopts) end
end

AddMethod("Gaussian", uigaussian, gaussian.paint_gaussian)
AddMethod("SMAA", uismaa, smaa.paint_SMAA)

-- options
-- all_frames: boolean -- apply antialiasing to all frames of current layer,
-- [color mask]: only calculates aliasing on top of a particular color
--  todo: could make this a range of colors
-- [alias color]: where edges are detected, apply only this color as a means of antialiasing
--  the idea to do this came from [here]() when I was trying to see if aseprite already had support
--  for antialiasing
local aa_defs = {
    all_frames = false,
}


-- todo: create an encompassing dialog class, that allows modular addition to its method options
-- each method registers itself with the parent dialog class (here it would be AA) when its file is
-- first loaded. this will make swapping between methods and not including them easier for binary
-- vs. lua versions
local function aa_dlog(prev_opts, prev_mopts)
    local opts = nil
    local mopts = nil

    local defs = aa_defs

    local dlog = Dialog("Apply Anti-aliasing")

    dlog:check{ id="all_frames", label="Apply to All Frames", selected=defs.all_frames }
        :combobox { id = "method", label = "Method",
            option = "Gaussian",
            options = { "Gaussian", "SMAA" }
        }
      :button { id = "pick_methodoptions", text = "Method Options", onclick = function()
        local cmethod = dlog.data.method
        local method_opts = method_dlog_map[cmethod](dlog, mopts or method_default_map[cmethod])
        if method_opts.ok then
          mopts = method_opts
        end
      end }
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

    opts = utils.cat(dlog.data)
    return { opts, mopts }
end

local function do_aa(opts, mopts)
    local ok, sp = pcall(function() return SpritePainter:new(utils.cat(opts, {
            use_active_layer = true
        }))
    end)
    if not ok then return end

    aa_methods[opts.method](sp, opts, mopts)
end

local function try_aa(prefs)
    local lc = prefs.last_command

    local sprite = app.activeSprite
    if not sprite then
        return app.alert("no active sprite to apply noise to")
    end

    local opts, mopts = table.unpack(aa_dlog(
        lc and lc.opts,
        lc and lc.mopts
    ))

    if opts.ok then
        app.transaction(
            "Anti-alias",
            function()
                do_aa(opts, mopts)
            end
        )
        app.refresh()

        return opts, mopts
    end

    return lc and lc.opts, lc and lc.mopts
end

return {
    aa_dlog = aa_dlog,
    aa_defs = aa_defs,
    do_aa = do_aa,
    try_aa = try_aa,
    aa =
    function(opts, mopts)
        app.transaction(
            "Anti-alias",
            function()
                do_aa(opts, mopts)
            end
        )
        app.refresh()
    end
}

