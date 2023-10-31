
local function paint_dots(sp, opts, mopts)
  sp.layer.name = "Dot Noise"

  local brush = app.activeBrush
  if mopts.use_brush and not brush then
    error(app.alert("dots.active_brush set but no active brush"))
  end

  for pixel in sp:pixels() do
    local r = math.random()
    if r < mopts.density then
      if mopts.use_brush then
        local pt = Point(pixel.x, pixel.y)
        app.useTool {
          tool = "pencil",
          color = app.fgColor,
          brush = brush,
          points = { pt },
          cel = sp.cel,
          layer = sp.layer
        }
      else
        pixel:put(app.fgColor)
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