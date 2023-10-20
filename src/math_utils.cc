#include "math_utils.h"


// wouldn't it be great if there was a standardized way to statically iterate over enum names haha,
// that'd be crazy :)
const char* DISTANCE_FUNC_NAMES[] = {
  "Euclidian",
  "Manhattan",
};

distance_func_t distance_funcs[] = {
  dist3<double>,
  mdist3<double>,
};


const char* INTERPOLATE_FUNC_NAMES[] = {
    "LERP",
    "CERP",
    "Smootherstep",
};

erp_func_t interpolate_funcs[] = {
  lerp<double>,
  cerp<double>,
  smootherstep<double>,
};