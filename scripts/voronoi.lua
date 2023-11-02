local utils = require("utils")

local voronoi_opt_defaults = {
    colors = 2,
    points = {5, 10},
    --distribution = "RANDOM", -- one of: { "RANDOM", "CELLS" }
    distance_func = utils.dist2,
    relax = true,
    relax_steps = 5,
    loop = false,
    movement = 10, -- how much a point may move over length
    movement_func = utils.lerp, -- { "LERP", "CERP", "smootherstep"}
    locations = 1,
}

local function find_nearest(x, y, points, dfunc)
    local first = points[1]
    local nearest = 1
    local dist = dfunc(x, y, first[1], first[2])

    for i=2,#points do
        local p = points[i]
        local new_dist = dfunc(x, y, p[1], p[2])
        if dist > new_dist then
            nearest = i
            dist = new_dist
        end
    end
    
    return nearest
end

-- returns an array as follows: [points][...]
-- where the second dimension is the set of all pixels associated with the given point
local function voronoi_graph(points, width, height, dfunc)
    local graph = {}
    for i=1,#points do
        graph[i] = {}
    end

    for x=0,width-1 do
        for y=0,height-1 do
            local nearest = find_nearest(x, y, points, dfunc)
            table.insert(graph[nearest], { x, y })
        end
    end

    return graph
end

-- todo: add rounded option, take on color out of the mix and add that to edges / bg
-- todo: add antialias flag
-- todo: add loop / grid option, where points are generated outside of the main canvas area, since 
-- as of now relaxing tends to pull points inwards

-- returns an array with dimensions [length][width*height]
local function voronoi(seed, width, height, length, options, loop)
    utils.set_default(options, voronoi_opt_defaults)

    math.randomseed(seed)

    local npoints = math.random(options.points[1], options.points[2])

    local points = {}

    -- generate random starting points within a padded area of the total width,height
    do
        local pwidth = width * 0.8
        local pheight = height * 0.8
        local pleft = (width-pwidth)/2
        local ptop = (height-pheight)/2
        for i=1,npoints do
            points[i] = { math.random()*pwidth + pleft, math.random()*pheight + ptop }
        end
    end

    -- relax the points
    if options.relax then
        for i=1,options.relax_steps do
            local graph = voronoi_graph(points, width, height, options.distance_func)

            points = { } -- reset points
            -- instead of trying to do an exact computation of the centroid, discreteze the space into
            -- pixels and just average those
            for p=1,#graph do
                points[p] = utils.centroid(graph[p])
            end
        end
    end

    local v = { }

    -- assign a color in range [1,#points] to each point
    local pcolors = { }
    for p=1, #points do
        pcolors[p] = math.random(options.colors)
    end

    local starting_points = { }
    for p=1, #points do starting_points[p] = points[p] end

    local from_points = { }
    local final_points = { }
    local move2 = 2*options.movement

    local gen_gap = math.floor(length/options.locations)
    local locations = 1

    local function gen_points()
        -- store the points that we start from, since points will be updated at each layer
        for p=1, #points do from_points[p] = points[p] end

        -- if we are looping and we are assigning the final location, just use the starting set of
        -- points as the final points
        if locations == options.locations and options.loop then
            final_points = starting_points
        else -- generate the points to be moved to over length
            for p=1, #points do
                local from = starting_points[p]
                final_points[p] = {
                    from[1] + math.random() * move2 - options.movement,
                    from[2] + math.random() * move2 - options.movement
                }
            end
        end
    end
    gen_points()

    local movef = options.movement_func

    -- generate the actual voronoi images
    for layer=1,length do
        local img = {}
        img[width*height] = 0 -- pre-alloc

        -- check if it's time to generate the next set of points
        if layer > locations * gen_gap then
            locations = locations + 1
            gen_points()
        end

        -- interpolate between the starting points and the end points
        local t = 0
        if length > 1 then
            -- todo: handle one frame of pause when reaching a location...
            local norm_layer = layer - (locations-1)*gen_gap
            t = (1 / (gen_gap-1)) * norm_layer + (1 / (-gen_gap + 1))
        end
        for p=1,#points do
            local from = from_points[p]
            local to = final_points[p]
            points[p] = {
                movef(from[1], to[1], t),
                movef(from[2], to[2], t)
            }
        end

        -- generate the actual graph with the interpolated points
        local graph = voronoi_graph(points, width, height, options.distance_func)
        for p=1,#graph do
            local color = pcolors[p]
            local pixels = graph[p]

            -- iterate over each pixel contained in point p's set and assign its colors in the image
            for i=1,#pixels do
                local pixel = pixels[i]
                img[width*pixel[2] + pixel[1]] = color
            end
        end

        v[layer] = img
    end

    return v
end

local function paint_voronoi(sp, opts, mopts)
    sp.layer.name = "Voronoi Graph"

    local frames = mopts.threed and mopts.frames or 1

    local color_range = opts.grad.colors

    local graphs = voronoi(opts.seed, sp.width, sp.height, frames, {
      colors = #color_range,
      points = { mopts.min_points, mopts.max_points },
      distance_func = mopts.distance_func == "Euclidian" and utils.dist2 or utils.mh_dist2,
      relax = mopts.relax,
      relax_steps = mopts.relax_steps,
      movement = mopts.movement,
      locations = mopts.locations,
      loop = mopts.loop
    }, {})

    for pixel in sp:animate(frames) do
      local graph = graphs[pixel.frame]
      pixel:put(color_range[graph[pixel.idx]])
    end
end

return {
    voronoi=voronoi,
    paint_voronoi=paint_voronoi
}