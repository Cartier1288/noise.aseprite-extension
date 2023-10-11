#include "math_utils.h"


// wouldn't it be great if there was a standardized way to statically iterate over enum names haha,
// that'd be crazy :)
const char* DISTANCE_FUNC_NAMES[] = {
    [EUCLIDIAN] = "EUCLIDIAN",
    [MANHATTAN] = "MANHATTAN",
};

double (*distance_funcs[])(double,double,double,double,double,double) = {
  [EUCLIDIAN] = dist3<double>,
  [MANHATTAN] = mdist3<double>,
};


const char* INTERPOLATE_FUNC_NAMES[] = {
    [LERP] = "LERP",
    [CERP] = "CERP",
    [SMOOTHERSTEP] = "SMOOTHERSTEP",
};

double (*interpolate_funcs[])(double,double,double) = {
  [LERP] = lerp<double>,
  [CERP] = cerp<double>,
  [SMOOTHERSTEP] = smootherstep<double>,
};