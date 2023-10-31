local function round(v)
  return math.floor(v + 0.5)
end

-- linear interpolate
local function lerp(p1, p2, t)
  return (p2 - p1) * t + p1;
end

-- cubic interpolate
local function cerp(p1, p2, t)
  return (p2 - p1) * (3.0 - t * 2.0) * t * t + p1;
end

local function smootherstep(p1, p2, t)
  return (p2 - p1) * ((t * (t * 6 - 15) + 10) * t * t * t) + p1
end

local function clamp01(v)
  return math.max(0, math.min(1, v))
end

local function clamp(min, max, v)
  return math.max(min, math.min(max, v))
end

local function color_grad(t, ...)
  local arg = { ... }

  -- app.alert("Length of args: " .. tostring(#arg))
  -- app.alert("t: " .. tostring(t))

  -- remember indexing starts from 1 :) :) :)
  local from = math.floor(t * (#arg - 1)) + 1
  local to = from   -- if t == 1, then we need to make sure that we don't go out of bounds
  if not (t == 1) then
    to = from + 1
  end

  -- app.alert("from: " .. tostring(from) .. ", to: " .. tostring(to))

  -- get adjusted t between the two color indices
  local adj_t = (t * (#arg - 1)) - (from - 1) -- adjust for +1 index :)

  from = arg[from]
  to = arg[to]

  return Color {
    r = lerp(from.red, to.red, adj_t),
    g = lerp(from.green, to.green, adj_t),
    b = lerp(from.blue, to.blue, adj_t),
    a = lerp(from.alpha, to.alpha, adj_t)
  }
end

local function color_grad_fixed(t, ...)
  local arg = { ... }

  -- remember indexing starts from 1 :) :) :)
  local cidx = round(t * (#arg - 1)) + 1

  return arg[cidx]
end

local function loop(v, from, diff)
  return ((v - from) % diff) + from
end

local function id(v)
  return v
end

-- stolen from: https://stackoverflow.com/a/27028488
local function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

local function set_default(table, defs)
  local mt = { __index = function(_, key) return defs[key] end }
  setmetatable(table, mt)
end

local function get_keys(t)
  local keys = {}

  for k, _ in pairs(t) do
    table.insert(keys, k)
  end

  return keys
end

local function sum(arr)
  local total = 0
  for _, v in ipairs(arr) do
    total = total + v
  end
  return total
end

local function mean(arr)
  return sum(arr) / #arr
end

local function dist2(x1, x2, y1, y2)
  local d1 = x1 - y1
  local d2 = x2 - y2
  return math.sqrt(d1 * d1 + d2 * d2)
end

-- Manhattan distance
local function mh_dist2(x1, x2, y1, y2)
  local d1 = x1 - y1
  local d2 = x2 - y2
  return math.abs(d1) + math.abs(d2)
end

local function centroid(points)
  local x, y = 0, 0

  for p = 1, #points do
    x = x + points[p][1]
    y = y + points[p][2]
  end

  x, y = x / #points, y / #points

  return { x, y }
end

-- ensures that the random number isn't 0, as unlikely as that may be
local function random_pos()
  local x
  repeat
    x = math.random()
  until not (x == 0)
  return x
end

local BINV_CUTOFF = 110

-- translated directly from GNU GSL gsl_ran_binomial
local function rbinom(p, n)
  local ix = 0
  local flipped = 0
  local q, s, np

  if n == 0 then
    return 0
  end

  if p > 0.5 then
    p = 1.0 - p
    flipped = 1
  end

  q = 1 - p
  s = p / q
  np = n * p   -- mean

  --if np < 14 then -- small mean
  local f0 = q ^ n

  while true do
    -- GSL source code mentioned the following:
    -- this while loop will almost certainly loop _only once_, unless u=1 is within a few
    -- epsilons of machine precision.

    local f = f0
    local u = math.random()

    for i = 0, BINV_CUTOFF do
      ix = i

      if u < f then
        goto Finish
      end

      u = u - f
      f = f * (s * (n - ix) / (ix + 1))
    end
  end
  -- todo when I can work up the will to write the rest of this algo out
  --else -- big mean, BTPE algorithm
  --    local k
  --
  --    local ffm = np + p
  --    local m = math.floor(ffm)
  --    local fm = m
  --    local xm = fm  + 0.5
  --    local npq = np * q

  --    local p1 = math.floor(2.195*math.sqrt(npq) - 4.6*q) + 0.5

  --    local xl = xm - p1
  --    local xr = xm + p1

  --    local c = 0.134 + 20.5 / (15.3 + fm)
  --    local p2 = p1 * (1.0 + c + c)

  --    local al = (ffm - xl) / (ffm - xl * p);
  --    local lambda_l = al * (1.0 + 0.5 * al);
  --    local ar = (xr - ffm) / (xr * q);
  --    local lambda_r = ar * (1.0 + 0.5 * ar);
  --    local p3 = p2 + c / lambda_l;
  --    local p4 = p3 + c / lambda_r;

  --    local var, accept
  --    local u, v

  --::TryAgain::
  --    u = math.random() * p4
  --    v = math.random()

  --    if u <= p1 then
  --        ix = math.floor(xm - p1*v + u)
  --        goto Finish
  --    elseif u <= p2 then
  --        local x = xl + (u - p1) / c
  --        v = v*c + 1 - math.abs(x - xm) / p1
  --        if v > 1.0 or v <= 0.0 then
  --            goto TryAgain
  --        end
  --        ix = math.floor(x)
  --    elseif u <= p3 then
  --        local ix = math.floor(xl + math.log(v)/lambda_l)
  --        if ix < 0 then
  --            goto TryAgain
  --        end
  --        v = v * ((u - p2) * lambda_l)
  --    else
  --        local ix = math.floor(xr - math.log(v)/lambda_r)
  --        if ix > n then
  --            goto TryAgain
  --        end
  --        v = v * ((u - p3) * lambda_r)
  --    end
  --end

  ::Finish::
  if flipped then
    return n - ix
  else
    return ix
  end
end

-- translated directly from GNU GSL gsl_ran_gamma_int
local function rgamma_i(a)
  if a < 12 then
    local prod = 1

    for i = 0, a - 1 do
      prod = prod * random_pos()
    end

    return -math.log(prod)
  else
    local sqa, x, y, v
    sqa = math.sqrt(2 * a - 1)

    repeat
      repeat
        y = math.tan(math.pi * math.random())
        x = sqa * y + a - 1;
      until x > 0
      v = math.random()
    until v <= (1 + y * y) * math.exp((a - 1) * math.log(x / (a - 1)) - sqa * y)

    return x
  end
end

local function rpoisson(mu)
  local k = 0

  -- todo this definitel does not distribute evenly ...
  -- for large mu -- translated from GNU GSL gsl_ran_poisson
  -- local rat = 7/8
  -- while mu > 10 do
  --     local m = math.floor(mu * rat)

  --     local X = rgamma_i(m)

  --     if X >= mu then
  --         return k + rbinom(mu / X, m - 1)
  --     else
  --         k = k + m
  --         mu = mu - X
  --     end

  -- end

  -- for small mu -- inverse transform sampling
  local x = 0
  local p = math.exp(-mu)
  local s = p

  local u = math.random()

  while u > s do
    x = x + 1
    p = p * (mu / x)
    s = s + p
  end

  return x
end

local function rnpoisson(mu, n)
  local rs = {}
  for i = 1, n do
    rs[i] = rpoisson(mu)
  end
  return rs
end

local function less(x, y)
  return x < y
end

local function greater(x, y)
  return x > y
end

-- insertion sort where n is the max number of elements in arr
local function insert_sortn(n, arr, val, cmp)
  cmp = cmp and cmp or less

  local insert_at = -1

  for i = 1, #arr do
    if cmp(val, arr[i]) then
      insert_at = i
      break
    end
  end

  -- just insert at the back of the array
  if insert_at == -1 then
    table.insert(arr, val)
  else
    table.insert(arr, insert_at, val)
  end

  -- pop end until we are in our limit
  while #arr > n do
    table.remove(arr)
  end
end

local function nclosest(n, points, arr, x, y, dfunc)
  for _, v in ipairs(points) do
    insert_sortn(n, arr, dfunc(x, y, v[1], v[2]), less)
  end
end

-- calculates the range of a function
local function range(arr, start)
  if #arr == 0 then return nil end
  if not start then start = 1 end

  local least = arr[start]
  local most = least

  for i=start,#arr-start do
    local val = arr[i]
    if val < least then least = val
    elseif val > most then most = val end
  end

  return least, most
end

-- scales a function into a desired range
local function scale(arr, start, new_min, new_max)
  if #arr == 0 then return nil end

  -- actual range
  local fmin, fmax = range(arr)

  local s = (new_max - new_min) / (fmax - fmin) -- scale

  for i=start,#arr-start do
    -- shift x to [0,frange], scale to [0,new_range], then shift by new_min
    arr[i] = (arr[i] - fmin) * s + new_min
  end

  return arr
end

local function timer_start()
  local t = os.clock();
  return function()
    return os.clock() - t
  end
end

local function timer_start_ms()
  local t = os.clock();
  return function()
    return (os.clock() - t) * 1000.0
  end
end

local function load_dlib(path, name)
  return package.loadlib(path, name)
end

local function try_load_dlib(name)
  local status, res = pcall(function() return require(name) end)

  if status then
    return res
  end

  -- if we were unable to load the dynamic library, return nil
  return nil
end

return {
  round = round,

  -- interpolation
  lerp = lerp,
  cerp = cerp,
  smootherstep = smootherstep,

  clamp01 = clamp01,
  clamp = clamp,

  color_grad = color_grad,
  color_grad_fixed = color_grad_fixed,

  loop = loop,
  id = id,
  dump = dump,
  set_default = set_default,
  get_keys = get_keys,

  mean = mean,
  sum = sum,

  -- distance functions
  dist2 = dist2,
  mh_dist2 = mh_dist2,

  centroid = centroid,
  less = less,
  greater = greater,
  insert_sortn = insert_sortn,
  nclosest = nclosest,
  range = range,
  scale = scale,

  -- random number generators
  rbinom = rbinom,
  rgamma_i = rgamma_i,
  rpoisson = rpoisson,
  rnpoisson = rnpoisson,

  timer_start = timer_start,
  timer_start_ms = timer_start_ms,

  try_load_dlib = try_load_dlib,
}

