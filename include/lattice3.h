#pragma once

#include "vector3.h"

#include <random>

class lattice3 {
    dvec3 offset;

    double cs; // cellsize
    dvec3 freq; // how often to repeat, in _cell_ units

    unsigned int seed;
    dvec3 scaled_freq;

public:
    lattice3(double cs, dvec3 freq);

    void set_seed(unsigned int);
    unsigned int get_seed(double x, double y, double z) const;

    dvec3 get_corner(double x, double y, double z) const;
    dvec3 get_corner(const dvec3& v) const;
    dvec3 point_rep(double x, double y, double z) const;
    dvec3 point_rep(const dvec3& v) const;
};