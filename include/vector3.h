#pragma once

#include <random>
#include <iostream>

template<typename T>
struct vector3 {
    T x, y, z;

    vector3()
        : x(T()), y(T()), z(T()) { }

    vector3(T x, T y, T z)  
        : x(x), y(y), z(z) { }

    vector3(T v)
        : x(v), y(v), z(v) { }

    vector3(const vector3& other)
        : x(other.x), y(other.y), z(other.z) { }

#define VEC_OP(op) \
    vector3 operator op (const vector3& other) const { \
        return vector3(x op other.x, y op other.y, z op other.z); \
    }
#define SCALAR_OP(op, type) \
    vector3 operator op (type a) const { \
        return vector3(x op a, y op a, z op a); \
    }

    VEC_OP(*)
    SCALAR_OP(*, double)

    VEC_OP(/)
    SCALAR_OP(/, double)

    VEC_OP(+)
    SCALAR_OP(+, double)

    VEC_OP(-)
    SCALAR_OP(-, double)

#undef VEC_OP
#undef SCALAR_OP

    bool operator==(const vector3& other) const {
        return x==other.x && y==other.y && z==other.z;
    }

    friend std::ostream& operator<<(std::ostream& out, vector3 const& v) {
        out << "< " 
            << v.x << ","
            << v.y << ","
            << v.z
            << " >";
        return out;
    }
};

namespace {
    // hashing functions borrowed from SO post (and its respective citations) here:
    // https://stackoverflow.com/a/7115547/2565202
    template<typename T>
    inline void hash_combine(std::size_t& seed, T const& v) {
        seed ^= std::hash<T>()(v) + 0x9E3779B9 + (seed<<6) + (seed>>2);
    }
}

// outline hashing function for vector3<T> for any T that has a defined hashing function
template<typename T>
struct std::hash<vector3<T>> {
    std::size_t operator()(const vector3<T>& v) const {
        size_t seed = 0;
        hash_combine(seed, v.x);
        hash_combine(seed, v.y);
        hash_combine(seed, v.z);
        return seed;
    }
};

typedef vector3<double> dvec3;