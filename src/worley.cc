#include "worley.h"

#include "isort.h"
#include "larray.h"
#include "lattice3.h"
#include "macro_utils.h"
#include "utils.h"
#include "vector3.h"

#include <assert.h>
#include <cmath>
#include <iostream>
#include <math.h>
#include <random>
#include <set>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

DECLARE_LUA_CLASS_NAMED(Worley, Worley);

#define GET_IDX(x, y) ((y)*width + (x))

typedef std::vector<dvec3> points_t;
typedef std::unordered_map<dvec3, points_t> cache_t;

size_t Worley::get_result_size() const { return width * height * n; }

static unsigned int gen_points(unsigned int seed, double mean, double min,
                               double max) {
  std::mt19937 gen(seed);
  std::poisson_distribution<> d(mean);
  return d(gen);
}

template <size_t N>
static inline void calc_dists(distance_func_t distf, isort<double, N>& dists,
                              dvec3& center, points_t& points) {
  for (dvec3 const& v : points) {
    double d = distf(v.x, v.y, v.z, center.x, center.y, center.z);
    dists.insert(d);
  }
}

template <size_t N>
void Worley::compute_frame(cache_t& cache, double z, double values[]) const {
  /* initialize random distributions  */
  std::mt19937 gen;
  std::poisson_distribution<> d(mean_points);
  // dist used to generate x,y,z offset inside of a cell
  std::uniform_real_distribution<> u(0.0, cellsize);

  lattice3 ltc(cellsize, freq);
  ltc.set_seed(seed);

  distance_func_t distf = distance_funcs[distance_func];

  dvec3 center{0, 0, z};
  for (double y = 0; y < height; y++) {
    size_t scanned = y * width;
    center.y = y;

    for (double x = 0; x < width; x++) {
      size_t idx = scanned + (size_t)x;
      dvec3 cell = ltc.get_corner(x, y, z);
      center.x = x;
      isort<double, N> dists;

      // test point does two things: it caches points assigned to each lattice
      // cell, and then it calculates the distance between pixel x,y,z and the
      // nearest points
      auto test_point = [&](dvec3 const& cell) {
        if (!cache.count(cell)) { // generate points, since we couldn't find
                                  // them in the cache
          cache[cell] = points_t{};
          points_t& points = cache[cell];

          auto grid_seed = ltc.get_seed(cell.x, cell.y, cell.z);
          gen.seed(grid_seed); // set seed using lattice
          d.reset();
          u.reset();

          size_t npoints = d(gen); // generate # of points using poisson

          points.reserve(npoints);

          for (size_t i = 0; i < npoints; i++) {
            // uniformly generate coordinates for each of n points
            points.push_back(
                dvec3(u(gen) + cell.x, u(gen) + cell.y, u(gen) + cell.z));
          }
        }

        calc_dists<N>(distf, dists, center, cache[cell]);
      };

      double zto = cell.z + cellsize;
      double yto = cell.y + cellsize;
      double xto = cell.x + cellsize;
      for (double cz = cell.z - cellsize; cz <= zto; cz += cellsize) {
        for (double cy = cell.y - cellsize; cy <= yto; cy += cellsize) {
          for (double cx = cell.x - cellsize; cx <= xto; cx += cellsize) {
            dvec3 corner(cx, cy, cz);
            test_point(corner);
          }
        }
      }
      /*
      // go to the top left
      cell.x -= cellsize;
      cell.y -= cellsize;

      test_point(cell);
      cell.x += cellsize;
      test_point(cell);
      cell.x += cellsize;
      test_point(cell);

      // middle-left
      cell.x -= cellsize*2;
      cell.y += cellsize;

      test_point(cell);
      cell.x += cellsize;
      test_point(cell);
      cell.x += cellsize;
      test_point(cell);

      // bottom-left
      cell.x -= cellsize*2;
      cell.y += cellsize;

      test_point(cell);
      cell.x += cellsize;
      test_point(cell);
      cell.x += cellsize;
      test_point(cell);
      */

      auto& vals = dists.get_values();
      constexpr_for<0, N, 1>([&](auto i) { values[idx * N + i] = vals[i]; });
    }
  }
}

template <size_t N>
Worley::result_t Worley::compute_frame(cache_t& cache, double z) const {
  result_t values(get_result_size());

  compute_frame<N>(cache, z, values.data());

  return values;
}

std::string Worley::to_string() const {
  std::stringstream str;

  str << "Worley { ";

  str << "seed: " << seed << ", ";
  str << "width: " << width << ", ";
  str << "height: " << height << ", ";
  str << "length: " << length << ", ";
  str << "mean_points: " << mean_points << ", ";
  str << "n: " << n << ", ";
  str << "cellsize: " << cellsize << ", ";
  str << "distance_func: " << distance_func << ", ";
  str << "movement: " << movement << ", ";
  str << "movement_func: " << movement_func << ", ";
  str << "freq: " << freq;

  str << " }";

  return str.str();
}

// could use try_get_num_field, but this is faster and less verbose :)
#define GET_NUMBER(idx, field, key)                                            \
  if (lua_getfield(L, idx, #key) != LUA_TNIL) {                                \
    W.field = luaL_checknumber(L, -1);                                         \
    lua_pop(L, 1);                                                             \
  }
#define GET_INTEGER(idx, field, key)                                           \
  if (lua_getfield(L, idx, #key) != LUA_TNIL) {                                \
    W.field = luaL_checkinteger(L, -1);                                        \
    lua_pop(L, 1);                                                             \
  }
#define GET_ENUM(idx, ENUM, enum_last, field, key)                             \
  if (lua_getfield(L, idx, #key) != LUA_TNIL) {                                \
    int val = luaL_checkinteger(L, -1);                                        \
    if (val < 0 || val >= enum_last)                                           \
      luaL_error(L, "invalid enum value passed as field");                     \
    W.field = (ENUM)val;                                                       \
    lua_pop(L, 1);                                                             \
  }
int Worley::lnew(lua_State* L) {
  Worley W; // start off default initialized, fill in as we go
  W.seed = std::random_device()(); // default init seed if there in case none is
                                   // given

  int idx = 1;

  if (lua_istable(L, idx)) {
    GET_NUMBER(idx, width, width);
    GET_NUMBER(idx, height, height);
    GET_INTEGER(idx, length, length);

    GET_NUMBER(idx, mean_points, mean_points);
    GET_INTEGER(idx, n, n);
    GET_NUMBER(idx, cellsize, cellsize);
    GET_ENUM(idx, DISTANCE_FUNC, DISTANCE_LAST, distance_func, distance_func);

    GET_NUMBER(idx, movement, movement);
    GET_ENUM(idx, INTERPOLATE_FUNC, INTERPOLATE_LAST, movement_func,
             movement_func);

    GET_INTEGER(idx, seed, seed);

    // get "loops" of form { x, y, z }
    if (lua_getfield(L, idx, "loops")) {
      bool is_table = lua_istable(L, -1);
      luaL_argexpected(L, is_table, idx, "expected table of form {x,y,z}");

      // make sure we were given a table !!
      if (!is_table)
        return 0;

      GET_NUMBER(-1, freq.x, x);
      GET_NUMBER(-1, freq.y, y);
      GET_NUMBER(-1, freq.z, z);

      lua_pop(L, 1);
    }
  } else if (lua_gettop(L) > 0) {
    luaL_error(L, "invalid argument passed to Worley constructor");
  }

  // copy our constructed Worley object into a userdata
  push_new<Worley>(L, W);

  // return Worley userdata object
  return 1;
}
#undef GET_ENUM
#undef GET_INTEGER
#undef GET_NUMBER

#define NTH_CASE(i, _)                                                         \
  case i: {                                                                    \
    worley->compute_frame<i>(cache, z, arr->values);                           \
    break;                                                                     \
  }

int Worley::compute(lua_State* L) {
  Worley* worley = get_obj<Worley>(L, 1);

  lua_createtable(L, worley->length, 0);

  erp_func_t mfun = interpolate_funcs[worley->movement_func];

  // cache to be used to avoid constantly recalculating Poisson + points, even
  // though the calcs. are repeatable given the same location+seed, it is heavy
  cache_t cache;

  double z = 0.0;
  double t = 0.0;
  double t_inc = 1.0 / (double)worley->length;
  for (double frame = 0; frame < worley->length; frame++) {
    lua_getglobal(L, "ldarray");

    int size = worley->get_result_size();

    // add ldarray size argument to stack
    lua_pushinteger(L, size);

    // call ldarray constructor
    if (lua_pcall(L, 1, 1, 0) != LUA_OK)
      return 0;

    auto arr = get_obj<larray<double>>(L, -1);

    // sanity check
    LASSERT(arr->size == worley->get_result_size(),
            "unexpected error, array size differs from Worley");

    // compute directly on top of the ldarray values
    switch (worley->n) {
      // TODO: if WORLEY_MAX_N is ever set > 9, then macro_utils will need to be
      // expanded to actually account for more "recursion"
      EVAL(REPEAT(WORLEY_MAX_N, NTH_CASE, ~))
    default:
      std::string err = std::string("unsupported Worley `n` given, 0 < n <= ") +
                        std::to_string(WORLEY_MAX_N);
      luaL_error(L, err.c_str());
      return 0;
    }

    // frames[frame+1] = arr
    lua_seti(L, -2, frame + 1);

    // move further in
    t += t_inc;
    z = mfun(0.0, worley->movement, t);
  }

  // return ldarray[]
  return 1;
}
#undef N_CASE

int Worley::to_string(lua_State* L) {
  Worley* worley = get_obj<Worley>(L, 1);

  // this is fine since Lua copies all pushed strings anyway
  lua_pushstring(L, worley->to_string().c_str());

  return 1;
}

void Worley::register_class(lua_State* L) {
  static const luaL_Reg methods[] = {{"compute", Worley::compute},
                                     {"__tostring", Worley::to_string},
                                     {nullptr, nullptr}};

  REG_LUA_CLASS(L, Worley, methods);
  REG_LUA_CNSTR(L, Worley, Worley::lnew);
}
