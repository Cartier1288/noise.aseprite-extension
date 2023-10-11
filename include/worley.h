#pragma once

#include "common.h"
#include "math_utils.h"

#include <vector>

class Worley {
public:
  typedef std::vector<double> result_t;

private:
  double width = 0; // width: double -- width in pixels
  double height = 0; // height: double -- height in pixels
  int length = 1; // length: int -- length in frames
  double mean_points = 0; // mean_points: double -- mean number of points per cel
  double n = 1; // n: double -- number of closest points to calculate
  double cellsize = 1; // cellsize: double -- size of each cell in pixels
  DISTANCE_FUNC distance_func = EUCLIDIAN; // distance_func: string/enum or function
  double movement = 0; // movement: double -- the amount of movement per frame
  INTERPOLATE_FUNC movement_func = LERP; // movement_func: string/enum or function -- lerp, cerp, etc.

  // colors: table -- colors to use 
  // clamp: double -- largest distance to keep, 0 for no clamp
  // combfunc: the combination to apply on top 
  // loop: table -- where to apply looping, x, y, z
  // loops: table -- at what cel values to apply looping, x, y, z

  size_t get_result_size() const;

public:
  // computes Worley noise given the current properties and fills a vector with them
  result_t compute() const;

  // computes Worley noise and fills the given array with them
  void compute(double values[]) const;

  static int lnew(lua_State* L);
  static int compute(lua_State* L);
  static void register_class(lua_State* L);
};