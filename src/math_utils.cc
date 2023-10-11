#include "math_utils.h"


// wouldn't it be great if there was a standardized way to statically iterate over enum names haha,
// that'd be crazy :)
const char* DISTANCE_FUNC_NAMES[] = {
    [EUCLIDIAN] = "EUCLIDIAN",
    [MANHATTAN] = "MANHATTAN",
};

distance_func_t distance_funcs[] = {
  [EUCLIDIAN] = dist3<double>,
  [MANHATTAN] = mdist3<double>,
};


const char* INTERPOLATE_FUNC_NAMES[] = {
    [LERP] = "LERP",
    [CERP] = "CERP",
    [SMOOTHERSTEP] = "SMOOTHERSTEP",
};

erp_func_t interpolate_funcs[] = {
  [LERP] = lerp<double>,
  [CERP] = cerp<double>,
  [SMOOTHERSTEP] = smootherstep<double>,
};