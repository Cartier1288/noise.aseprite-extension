
local adjusted = false
local function fix_path()
  if not adjusted then
    adjusted = true;

    local pwd = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]
    local prefixes = { "", "scripts/" }
    for _,prefix in ipairs(prefixes) do
      package.path = pwd .. prefix .. "?.lua;" .. package.path
      package.path = pwd .. prefix .. "?/init.lua;" .. package.path
      package.cpath = pwd .. prefix .. "bin/?.so;" .. package.cpath
      package.cpath = pwd .. prefix .. "bin/?.a;" .. package.cpath
      package.cpath = pwd .. prefix .. "bin/?.dll;" .. package.cpath
      package.cpath = pwd .. prefix .. "bin/?.dylib;" .. package.cpath
    end
  end
end

function init(plugin)
  print("initializing Noise plugin")

  local group = "edit_generate"

  -- reset last command
  plugin.preferences.last_command = { }

  plugin:newMenuGroup {
    id = group,
    title = "Generate",
    group = "edit_fill"
  }

  plugin:newCommand {
    id = "gennoise",
    title = "Generate Noise",
    group = group,
    onclick = function()
      fix_path()

      -- requiring here means that error messages that would have been on plugin startup can
      -- be recorded
      local noise = require("scripts.noise")
      local opts, mopts = noise.noise_try({ last_command = plugin.preferences.last_command.noise })

      plugin.preferences.last_command.noise = { opts=opts, mopts=mopts, sprite=app.sprite, type="noise" }
    end
  }

  plugin:newCommand {
    id = "gennoise_repeat",
    title = "Repeat Last Noise",
    group = group,
    onclick = function()
      local lc = plugin.preferences.last_command.noise
      if lc then
        if lc.sprite ~= app.sprite then
          app.alert("Error! Cannot repeat noise on a different sprite.")
          return
        end
        local pwd = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]

        local noise = require("scripts.noise")
        -- refresh the seed, since presumably the user wants a different seed if they are repeating
        -- the generation
        lc.opts.seed = noise.get_seed()
        noise.noise(lc.opts, lc.mopts)
      else
        app.alert("Warning! No noise to repeat.")
      end
    end
  }

  plugin:newCommand {
    id = "antialias",
    title = "Anti-alias",
    group = group,
    onclick = function()
      fix_path()

      -- requiring here means that error messages that would have been on plugin startup can
      -- be recorded
      local aa = require("aa")

      local opts, mopts = aa.try_aa({ last_command = plugin.preferences.last_command.aa })

      plugin.preferences.last_command.aa = { opts=opts, mopts=mopts, sprite=app.sprite }
    end
  }

  print("finished loading Noise plugin")
end

function exit(plugin)
  print("closing Noise plugin")
end
