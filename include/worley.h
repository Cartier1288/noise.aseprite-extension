#pragma once

#include "common.h"

#include <vector>

class Worley {
public:
  typedef std::vector<double> result_t;

private:
  double width; // width: double -- width in pixels
  double height; // height: double -- height in pixels
  int length; // length: int -- length in frames
  double mean_points; // mean_points: double -- mean number of points per cel
  double n; // n: double -- number of closest points to calculate
  double cellsize; // cellsize: double -- size of each cell in pixels
  int distance_func; // distance_func: string/enum or function
  double movement; // movement: double -- the amount of movement per frame
  int movement_func; // movement_func: string/enum or function -- lerp, cerp, etc.

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

  static int compute(lua_State* L);
};