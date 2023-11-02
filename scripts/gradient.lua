local utils = require("utils.utils-misc")

local Gradient = { }

-- for now, we assume that there will always be at least two colors, what's the point of a gradient
-- otherwise :)
-- todo: make cutoffs, midpoints optional (calculated otherwise), and add custom midpoint
-- calculations so that colors can be stretched without changing the location of another
function Gradient:new(colors, cutoffs, opts)
    local this = { }
    setmetatable(this, self)
    self.__index = self

    this.colors = colors
    -- cutoffs is a sorted array of size #colors, with elements in (0, 1)
    this.cutoffs = cutoffs

    this.min = cutoffs[1]
    this.max = cutoffs[#cutoffs]

    this.mid = math.ceil(#cutoffs/2)
    this.start = 1
    this.last = #cutoffs
    this.ncolors = #colors

    this:gen_midpoints()

    return this
end

function Gradient:get_midpoint(idx)
    if idx == 0 then return 0 end
    if idx == self.ncolors then return 1 end
    return self.midpoints[idx]
end

function Gradient:get_cutoff(idx)
    if idx == 0 then return 0 end
    if idx == self.ncolors+1 then return 1 end
    return self.cutoffs[idx]
end

-- gets the range of a particular color
function Gradient:get_range(idx)
    local min, max = 0, 1

    if idx > 1 then
        min = self.midpoints[idx-1]
    end
    if idx < #self.colors then
        max = self.midpoints[idx]
    end

    return min, max
end

function Gradient:gen_midpoints()
    self.midpoints = { }
    for i=1,#self.cutoffs-1 do
        local first = self.cutoffs[i]
        local second = self.cutoffs[i+1]
        self.midpoints[i] = (first + second) / 2;
    end
end


-- note:
-- another more efficient approach might be to limit the precision of t values such that an array
-- of say 1000 elements can be created for fast access
-- this would reduce the fidelity of the gradient around edges somewhat, but it probably wouldn't
-- be visible
function Gradient:get_idx(t)

    --[[
    if t < self.min then
        return self.colors[1]
    elseif t >= self.max then
        return self.colors[self.last]
    end
    --]]

    -- simple heuristic of starting at the idx if gradient is dispersed evenly
    -- local idx = math.floor(t * (self.ncolors-1))+1
    local idx = self.mid

    local jumped_left = false
    local jumped_right = false

    if t == 0 then return self.start 
    elseif t == 1 then return self.last end

    while true do
        if t >= self:get_midpoint(idx) then
            if jumped_left then
                return idx+1
            end
            idx = idx + 1
            jumped_right = true
        else
            if jumped_right then
                return idx
            end
            idx = idx - 1
            jumped_left = true
        end
    end
end

function Gradient:get_between(t)
    local idx = self.mid

    local jumped_left = false
    local jumped_right = false

    while true do
        --print(string.format("(%.3f) %d:%.2f", t, idx, self:get_cutoff(idx)))
        if t >= self:get_cutoff(idx) then
            if jumped_left then
                return idx,idx+1
            end
            idx = idx + 1
            jumped_right = true
        else
            if jumped_right then
                return idx-1,idx
            end
            idx = idx - 1
            jumped_left = true
        end
    end
end

-- discrete gradient
function Gradient:color_disc(t)
    return self.colors[self:get_idx(t)]
end

-- continuous gradient
function Gradient:color_cont(t)
    if t <= self.min then
        return self.colors[self.start]
    elseif t >= self.max then
        return self.colors[self.last]
    end

    local from, to = self:get_between(t)
    local adj_t = (t - self.cutoffs[from]) / (self.cutoffs[to] - self.cutoffs[from])
    --print(string.format("%.3f->%.3f <=> %.3f", self.cutoffs[from], self.cutoffs[to], adj_t))
    return utils.color_grad_given(adj_t, self.colors[from], self.colors[to])
end


return Gradient