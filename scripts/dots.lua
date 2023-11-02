
local function paint_dots(sp, opts, mopts)
  sp.layer.name = "Dot Noise"

  local brush = app.activeBrush
  if mopts.use_brush and not brush then
    error(app.alert("dots.active_brush set but no active brush"))
  end

  -- todo: could use discrete grad size as a way of determining likelihood of a particular color
  local color_range = opts.grad.colors
  local ncolors = #color_range

  for pixel in sp:pixels() do
    local r = math.random()
    if r < mopts.density then
      local color = color_range[math.random(ncolors)]

      if mopts.use_brush then
        local pt = Point(pixel.x, pixel.y)
        app.useTool {
          tool = "pencil",
          color = color,
          brush = brush,
          points = { pt },
          cel = sp.cel,
          layer = sp.layer
        }
      else
        pixel:put(color)
      end
    end
  end

  -- layer alpha mask cleanup
  if mopts.use_brush then
    sp:apply_masks()
  end

end

return {
    paint_dots=paint_dots
}