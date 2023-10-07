function init(plugin)
  print("initializing Noise plugin")

  local group = "edit_generate"

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

      -- requiring here means that error messages that would have been on plugin startup can
      -- be recorded
      local noise = require("scripts.noise")
      noise.noise_try()
    end
  }

  print("finished loading Noise plugin")
end

function exit(plugin)
  print("closing Noise plugin")
end
