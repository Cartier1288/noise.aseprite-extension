#pragma once

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
    vector3 operator op (const vector3& other) { \
        return vector3(x op other.x, y op other.y, z op other.z); \
    }
#define SCALAR_OP(op, type) \
    vector3 operator op (type a) { \
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
};

typedef vector3<double> dvec3;