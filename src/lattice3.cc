#include "lattice3.h"

#include "math_utils.h"

#include <time.h>
#include <math.h>
#include <cmath>
#include <random>

lattice3::lattice3(double cs, dvec3 freq)
    : cs(cs), freq(freq), offset(0),
      seed(std::random_device()()),
      scaled_freq(freq*cs)
{}

void lattice3::set_seed(unsigned int new_seed) {
    seed = new_seed;
}


unsigned int lattice3::get_seed(double x, double y, double z) const {
    dvec3 corner = point_rep(get_corner(x + offset.x, y + offset.y, z + offset.z));

    size_t cseed = std::hash<dvec3>{}(corner);
    hash_combine(cseed, seed);

    /*unsigned int cseed = (
        (long)(corner.x * 18732251.0) +
        (long)(corner.y * 18735419.0) +
        (long)(corner.z * 18738667.0)) 
        % 187753493L + seed;*/

    return cseed;
}

dvec3 lattice3::get_corner(double x, double y, double z) const {
    return dvec3(
        floor(x / cs) * cs,
        floor(y / cs) * cs,
        floor(z / cs) * cs
    );
}

dvec3 lattice3::get_corner(const dvec3& v) const {
    return dvec3(
        floor(v.x / cs) * cs,
        floor(v.y / cs) * cs,
        floor(v.z / cs) * cs
    );
}

dvec3 lattice3::point_rep(double x, double y, double z) const {
    return dvec3(
        freq.x == 0 ? x : pmod(x, scaled_freq.x),
        freq.y == 0 ? y : pmod(y, scaled_freq.y),
        freq.z == 0 ? z : pmod(z, scaled_freq.z)
    );
}

dvec3 lattice3::point_rep(const dvec3& v) const {
    return dvec3(
        freq.x == 0 ? v.x : pmod(v.x, scaled_freq.x),
        freq.y == 0 ? v.y : pmod(v.y, scaled_freq.y),
        freq.z == 0 ? v.z : pmod(v.z, scaled_freq.z)
    );
}
