function init(plugin)
  print("initializing Noise plugin")

  local group = "edit_generate"

  -- reset last command
  plugin.preferences.last_command = nil

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
      local pwd = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]
      package.path = pwd .. "?.lua;" .. package.path
      package.cpath = pwd .. "bin/?.so;" .. package.cpath
      package.cpath = pwd .. "bin/?.a;" .. package.cpath
      package.cpath = pwd .. "bin/?.dll;" .. package.cpath

      -- requiring here means that error messages that would have been on plugin startup can
      -- be recorded
      local noise = require("scripts.noise")
      local opts, mopts = noise.noise_try(plugin.preferences)

      plugin.preferences.last_command = { opts=opts, mopts=mopts, sprite=app.sprite }
    end
  }

  plugin:newCommand {
    id = "gennoise_repeat",
    title = "Repeat Last Noise",
    group = group,
    onclick = function()
      local lc = plugin.preferences.last_command
      if lc then
        if lc.sprite ~= app.sprite then
          app.alert("Error! Cannot repeat noise on a different sprite.")
          return
        end
        local pwd = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]
        package.path = pwd .. "?.lua;" .. package.path
        package.cpath = pwd .. "bin/?.so;" .. package.cpath
        package.cpath = pwd .. "bin/?.a;" .. package.cpath
        package.cpath = pwd .. "bin/?.dll;" .. package.cpath
        package.cpath = pwd .. "bin/?.dylib;" .. package.cpath

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

  print("finished loading Noise plugin")
end

function exit(plugin)
  print("closing Noise plugin")
end
