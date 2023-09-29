function init(plugin)
    local noise = require("noise")

    print("initializing Noise plugin")

    local group = "edit_generate"

    plugin:newMenuGroup{
        id=group,
        title="Generate",
        group="edit_fill"
    }

    plugin:newCommand{
        id="gennoise",
        title="Generate Noise",
        group=group,
        onclick=function()
            noise.noise_try()
        end
    }
end

function exit(plugin)
    print("closing Noise plugin")
end