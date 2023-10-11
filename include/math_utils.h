#pragma once

#include <math.h>

template<typename T>
T dist2(T v1, T v2, T w1, T w2) {
    T d1 = w1 - v1;
    T d2 = w2 - v2;
    return sqrt(d1*d1 + d2*d2);
}

template<typename T>
T dist3(T v1, T v2, T v3, T w1, T w2, T w3) {
    T d1 = w1 - v1;
    T d2 = w2 - v2;
    T d3 = w3 - v3;
    return sqrt(d1*d1 + d2*d2 + d3*d3);
}

template<typename T>
T mdist2(T v1, T v2, T w1, T w2) {
    T d1 = w1 - v1;
    T d2 = w2 - v2;
    return fabs(d1) + fabs(d2);
}

template<typename T>
T mdist3(T v1, T v2, T v3, T w1, T w2, T w3) {
    T d1 = w1 - v1;
    T d2 = w2 - v2;
    T d3 = w3 - v3;
    return fabs(d1) + fabs(d2) + fabs(d3);
}

enum DISTANCE_FUNC {
  EUCLIDIAN=0,
  MANHATTAN,
  
  DISTANCE_LAST
};

extern const char* DISTANCE_FUNC_NAMES[];

extern double (*distance_funcs[])(double,double,double,double,double,double);


template<typename T>
T lerp(T p1, T p2, T t) {
    return (p2 - p1) * t + p1;
}

template<typename T>
T cerp(T p1, T p2, T t) {
    return (p2 - p1) * (3.0 - t*2.0) * t*t + p1;
}

template<typename T>
T smootherstep(T p1, T p2, T t) {
    return (p2 - p1) * ((t * (t*6 - 15) + 10) * t*t*t) + p1;
}


enum INTERPOLATE_FUNC {
  LERP=0,
  CERP,
  SMOOTHERSTEP,

  INTERPOLATE_LAST
};

extern const char* INTERPOLATE_FUNC_NAMES[];

extern double (*interpolate_funcs[])(double,double,double);