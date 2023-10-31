local utils = require("utils")

local SpritePainter = { }

-- meant to factor common functionality between noise generator scripts
-- e.g., getting/creating layers, drawing in a mode-independent way, etc.
-- opts: {
--      use_active_layer,
--      lock_alpha
-- }
function SpritePainter:new(opts) -- noexcept(false)
    local this = { }
    setmetatable(this, self)
    self.__index = self

    this.use_active_layer = opts.use_active_layer
    this.lock_alpha = opts.use_active_layer and opts.lock_alpha

    -- canvas data:
    --  sprite
    --  layer
    --  cel
    --  palette
    --  width
    --  height
    -- alphas

    this:load_sprite_data()
    this:bind_canvas_functions()
    this:load_sprite_alpha()
    this:init_color_grad()

    return this
end

function SpritePainter:_get_color_index(idx)
    return self.palette:getColor(idx)
end

function SpritePainter:_get_color_uint(val)
    return Color(val)
end

function SpritePainter:_get_alpha_index(idx)
    if idx == self.image.spec.transparentColor then
        return 0
    end

    return self.palette:getColor(idx).alpha
end

function SpritePainter:_get_alpha_uint(val)
    return app.pixelColor.rgbaA(val)
end

function SpritePainter:get_color_at(x,y)
    return self:get_color(self.image:getPixel(
        x - self.cel.position.x,
        y - self.cel.position.y
    ))
end

-- TODO: create a gradient class of some stripe, to make this picking more complete
-- this class should also offer fixed values (i.e., a discrete gradient)
function SpritePainter:pick_color(t)
    return utils.color_grad(t, table.unpack(self.color_range))
end

function SpritePainter:load_sprite_data()
    self.sprite = app.sprite
    if not self.sprite then
        error(app.alert("no active sprite"))
    end

    if self.use_active_layer then
        self:get_current_frame()
    else
        self.layer = self.sprite:newLayer()
        self:load_frame(1)
    end
    self.frame = 1

    self.palette = self.sprite.palettes[1]

    self.width = self.sprite.width
    self.height = self.sprite.height
end

function SpritePainter:load_sprite_alpha()
    self.alphas = { }
    if not self.lock_alpha then
        return
    end

    -- cels are _not_ the full width of the sprite, their proportions are always their minimum
    -- bounding rectangles.
    
    local bounds = self.image.bounds
    local left = self.cel.position.x
    local right = left + bounds.w
    local top = self.cel.position.y
    local bottom = top + bounds.h

    -- init everything to 0 to begin with
    for x = 0, self.width - 1 do
      self.alphas[x] = {}
      self.alphas[x][self.height-1] = 0
      for y = 0, self.height - 1 do
        self.alphas[x][y] = 0
      end
    end

    for it in self.image:pixels() do
      -- the actual image is at least as small as the cel, so assign each of its pixels based on
      -- its bounds and offset from the cel start
      self.alphas[it.x + left][it.y + top] = self:get_alpha(it())
    end
end

-- 
function SpritePainter:bind_canvas_functions()
    -- depending on the color mode, val may be either an integer representing the color itself, or
    -- an index into the palette
    if self.image.colorMode == ColorMode.INDEXED then
        self.get_color = self._get_color_index
        self.get_alpha = self._get_alpha_index
    else
        self.get_color = self._get_color_uint
        self.get_alpha = self._get_alpha_uint
    end
end

function SpritePainter:init_color_grad()
  self.color_range = { app.bgColor, app.fgColor }
  if #(app.range.colors) > 1 then
    self.color_range = {}
    for i = 1, #app.range.colors do
      self.color_range[i] = self.palette:getColor(app.range.colors[i])
    end
  end
end

function SpritePainter:get_current_frame()
    self.layer = app.layer
    self.cel = app.cel
    if not self.layer or not self.cel then
        error(app.alert("SpritePainter tried to get active layer+cel, but couldn't find one"))
    end
    self.image = self.cel.image
end

function SpritePainter:load_frame(idx)
    if idx > #self.sprite.frames then
        self.sprite:newEmptyFrame(idx)
    end

    self.cel = self.sprite:newCel(self.layer, idx)
    self.image = self.cel.image;
end

function SpritePainter:put_pixel(x, y, color)
    if self.lock_alpha then
        -- TODO: turn this pattern into its own "mask" system, where we can just apply masks in some
        -- order on top of a given color
        color = Color {
            red = color.red,
            green = color.green,
            blue = color.blue,
            alpha = self.alphas[x][y]
        }
    end
    self.image:drawPixel(x, y, color)
end

-- pixel iterator
function SpritePainter:pixels()
    local i = -1

    local sp = self
    local pixel = {
        x=-1, y=0, idx=0
    }
    function pixel:put(color)
        sp:put_pixel(self.x, self.y, color)
    end

    local n = self.width * self.height
    return function()
        i = i + 1
        pixel.idx = i

        pixel.x = pixel.x + 1
        if pixel.x >= self.width then
            pixel.x = 0
            pixel.y = pixel.y + 1
        end

        if i < n then
            return pixel
        end
    end
end

-- wraps pixel iterator, and also adds frames when necessary
function SpritePainter:animate(frames)
    local it = self:pixels()
    local pixel

    local frame = 1
    self:load_frame(frame)

    return function()
        pixel = it()

        if not pixel then
            frame = frame + 1

            -- restart pixel iterator every frame
            if frame <= frames then
                self:load_frame(frame)
                it = self:pixels()
                pixel = it()
            end
        end

        if frame <= frames then
            pixel.frame = frame
            return pixel
        end
    end
end

-- this applies masks, useful for functions that draw pixels in other ways
function SpritePainter:apply_masks()
    for pixel in self:pixels() do
        pixel:put(self:get_color_at(pixel.x, pixel.y))
    end
end

return {
    SpritePainter = SpritePainter
}