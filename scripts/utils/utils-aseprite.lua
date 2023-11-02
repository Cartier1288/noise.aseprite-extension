local utils = require("utils.utils-misc")
local Gradient = require("gradient")

-- creates custom data aggregator

local DialogCustomData = { }
function DialogCustomData:new(dlog)
    local this = { }
    setmetatable(this, self)
    self.__index = self

    this.dlog = dlog
    this.getters = { }

    return this
end

-- custom data widgets call this to register a way to actually get / aggregate the data they make
-- function should have signature: DataReturnValue getter(Dialog)
function DialogCustomData:register(id, getter)
    self.getters[id] = getter
end

function DialogCustomData:get(id)
    return self.getters[id](self.dlog)
end


function Dialog_gradient(dlog, data, opts)
    -- get a fresh "copy" of the colors, we can now adjust the order
    local selected_color = nil
    local colors = utils.cat(opts.colors)
    local cutoffs = { }

    local preview_height = 5

    -- cutoffs are the "start" of a color, everything before the first cutoff is also that color as
    -- well as everything that is after the last is also the last color
    local compute_cutoff = function()
        for i=1, #colors do
            cutoffs[i] = (i-1)/(#colors-1)
        end
    end
    compute_cutoff()

    local colors_id = opts.id .. "-shades"
    local selected_id = opts.id .. "-selected"
    local slider_id = opts.id .. "-cutoff"

    local get_color_idx = function(color)
        return utils.find(colors, color)
    end
    local get_cutoff = function(color)
        return cutoffs[get_color_idx(color)]
    end

    local get_range = function(color)
        local idx = get_color_idx(color)

        local min, max = 0, 1

        if idx > 1 then
            min = cutoffs[idx-1]
        end
        if idx < #colors then
            max = cutoffs[idx+1]
        end

        return min, max
    end

    local get_range_string = function(min, max)
        return string.format(
            "[%.2f, %.2f]",
            min, max
        )
    end

    local get_cutoff_str = function(color)
        local t = get_cutoff(color)
        return string.format(
            "%.2f", t
        )
    end

    local get_selected_opts = function()
        if selected_color then
            return {
                id=selected_id,
                text=tostring(get_color_idx(selected_color)) .. ": " .. get_cutoff_str(selected_color),
            }
        end
        return {
            id=selected_id,
            text="No Color Selected",
        }
    end

    local function get_slider_opts()
        local idx = get_color_idx(selected_color)

        local active = not not idx

        local min, max = 0, 0
        local scale = 100
        local range_str = ""

        if active then
            min, max = get_range(selected_color)
            range_str = " " .. get_range_string(min, max)

            min = min * scale
            max = max * scale
        end

        return {
            id=slider_id,
            label="Cutoff" .. range_str,
            min = min,
            max = max,
            value = active and cutoffs[idx] * scale or 0,
            visible = active,
            onchange = function()
                local cidx = get_color_idx(selected_color)
                if cidx then
                    cutoffs[cidx] = dlog.data[slider_id]/scale
                    dlog:modify(get_selected_opts())
                    dlog:repaint()
                end
            end
        }
    end

    local get_shades_opts = function()
        return {
            id=colors_id,
            colors = colors,
            mode="sort",
            onclick = function(ev)
                selected_color = ev.color

                local new_colors = utils.cat(dlog.data[colors_id])
                local new_cutoffs = { }
                -- if #colors is reduced, this just chops off the end cutoff
                for i=1,#new_colors do new_cutoffs[i] = cutoffs[i] end

                colors = new_colors
                cutoffs = new_cutoffs

                dlog:modify(get_selected_opts())
                dlog:modify(get_slider_opts())
                dlog:repaint()
            end
        }
    end

    dlog:button{
        id=opts.id .. "-label",
        label=opts.label,
        text="Flip Colors",
        onclick = function()
            colors = utils.flip(colors)
            dlog:modify(get_shades_opts())
            dlog:modify(get_selected_opts())
            dlog:modify(get_slider_opts())
            dlog:repaint()
        end
    }
    dlog:shades(get_shades_opts())
    dlog:canvas{
        id=opts.id .. "-disc-canvas",
        height=preview_height,
        onpaint=function(ev)
            local ctx = ev.context
            local grad = Gradient:new(dlog.data[colors_id], cutoffs, { })

            local cwidth = ctx.width

            for i, color in ipairs(colors) do
                local min, max = grad:get_range(i)
                min, max = min*cwidth, max*cwidth

                ctx.color = color
                --todo: uses width here since some ratios get blank spaces, figure that out so that
                --extra pixels don't need to be drawn
                ctx:fillRect(Rectangle(min, 0, cwidth, preview_height))
            end
        end
    }
    dlog:newrow()
    dlog:canvas{
        id=opts.id .. "-cont-canvas",
        height=preview_height,
        onpaint=function(ev)
            local ctx = ev.context
            local grad = Gradient:new(dlog.data[colors_id], cutoffs, { })

            local cwidth = ctx.width

            for x=0, cwidth-1 do
                ctx.color = grad:color_cont(x/cwidth)
                ctx:fillRect(Rectangle(x, 0, 1, preview_height))
            end
        end
    }
    dlog:label(get_selected_opts())
    -- slider between the min of this color and max of the next
    dlog:slider(get_slider_opts())

    data:register(opts.id, function()
        return {
            colors = dlog.data[colors_id],
            cutoffs = cutoffs
        }
    end)
end

local function get_selected_colors(sprite)
    local palette = sprite.palettes[1]
    local color_range = { app.bgColor, app.fgColor }

    if #(app.range.colors) > 1 then
        color_range = {}
        for i = 1, #app.range.colors do
            color_range[i] = palette:getColor(app.range.colors[i])
        end
    end

    return color_range
end

local function format_color(color)
    return string.format(
        "{ r=%d, g=%d, b=%d, a=%d }",
        color.red,
        color.green,
        color.blue,
        color.alpha
    )
end

return {
    DialogCustomData = DialogCustomData,
    Dialog_gradient = Dialog_gradient,
    get_selected_colors = get_selected_colors,
    format_color = format_color
}