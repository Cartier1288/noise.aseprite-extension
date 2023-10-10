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