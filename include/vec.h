#pragma once

#include <cstddef>
#include <array>
#include <type_traits>
#include <cmath>
#include <algorithm>
#include <assert.h>


#include <iostream>

template<size_t... inds, class F>
constexpr void unroll(std::integer_sequence<size_t, inds...>, F&& f) {
    (f(std::integral_constant<size_t, inds>{}), ...);
}

template<size_t len, class F>
constexpr void unroll(F&& f) {
    unroll(std::make_integer_sequence<size_t, len>{}, std::forward<F>(f));
}

// the assumption here is that vec is being used for small N
// vec is really just meant to parallel float4/vec4 etc. seen in hlsl/glsl
template<typename T, size_t N>
class vec {
private:
    std::array<T, N> vals;

public:
    vec() { }

    // todo try and find a way to prefer implicit conversion from double -> float over using the
    // other template extended init constructor
    explicit vec(T val) {
        unroll<N>([&, this](auto i) {
            vals[i] = val;
        });
    }

    vec(vec const& other) {
        unroll<N>([&, this](auto i) {
            vals[i] = other[i];
        });
    }

    template<typename TT>
    vec(vec<TT, N> const& other) {
        static_assert(std::is_convertible<T, TT>::value, "invalid vec primary type cast");
        unroll<N>([&, this](auto i) {
            vals[i] = other[i];
        });
    }
    
    // variadic constructor gets preferred over const copy constructor without this
    template<typename TT>
    vec(vec<TT, N> & other)
        : vec(const_cast<vec<TT, N> const&>(other)) { }

    vec(vec&& other) {
        unroll<N>([&, this](auto i) {
            vals[i] = other[i];
        });
    }

    template<typename TT=T, typename... Args,
        std::enable_if_t<
            std::is_constructible<T, TT>::value &&
            (std::is_constructible<T, Args>::value && ...) &&
            !std::is_same<std::decay_t<TT>, vec>::value,
            int
        > = false
    >
    explicit vec(TT&& v, Args&&... args) 
        : vals{std::forward<T>(v), std::forward<T>(args)...}
    { static_assert(sizeof...(args)+1 == N, "# of arguments passed to full vec initialization differs from N");  }


    void operator=(vec const& other) {
        unroll<N>([&, this](auto i) {
            vals[i] = other[i];
        });
    }

    template<typename TT>
    void operator=(vec<TT, N> const& other) {
        unroll<N>([&, this](auto i) {
            vals[i] = other[i];
        });
    }

    template<typename TT>
    void operator=(TT val) {
        unroll<N>([&, this](auto i) {
            vals[i] = val;
        });
    }

    inline T operator[](size_t idx) const { 
        // todo remove this when done debugging lol
        if(idx >= N) {
            assert(idx < N);
        } return vals[idx]; }
    inline T& operator[](size_t idx) { 
        if(idx >= N) {
            assert(idx < N); 
        }return vals[idx]; }


#define SCALAR_OP(op)                                            \
    template<typename TT, typename VT, size_t M> \
    friend vec<VT, M> operator op (vec<VT, M> const& v, TT const& val); \
    template<typename TT, typename VT, size_t M> \
    friend vec<VT, M> operator op (TT const& val, vec<VT, M> const& v);
    SCALAR_OP(+)
    SCALAR_OP(-)
    SCALAR_OP(*)
    SCALAR_OP(/)
#undef SCALAR_OP

#define VEC_OP(op)                                                          \
    template<typename T1, typename T2, size_t M> \
    friend auto operator op (vec<T1, M> const& v1, vec<T2, M> const& v2) \
    -> vec<std::decay_t<decltype(T1() op T2())>, M>;
    VEC_OP(+)
    VEC_OP(-)
    // even though this may make no sense in the lin.alg. world, here we just assume that all
    // vector operators are element-wise
    VEC_OP(*)
    VEC_OP(/)
#undef VEC_OP    


#define SCALAR_OPEQ(op)                                                  \
    template<typename TT> \
    vec& operator op (TT val) {                         \
        unroll<N>([&, this](auto i) { vals[i] op val; }); \
        return *this; \
    }
    SCALAR_OPEQ(+=)
    SCALAR_OPEQ(-=)
    SCALAR_OPEQ(*=)
    SCALAR_OPEQ(/=)
#undef VEC_OPEQ 

// todo consider allowing automatic type deduction here, so that thinks like:
// (int4)v * (float4)w works and deduces to floating type.
#define VEC_OPEQ(op)                                                  \
    template<typename TT> \
    vec& operator op (vec<TT, N> const& other)  {                         \
        unroll<N>([&, this](auto i) { vals[i] op other.vals[i]; }); \
        return *this; \
    }
    VEC_OPEQ(+=)
    VEC_OPEQ(-=)
    VEC_OPEQ(*=)
    VEC_OPEQ(/=)
#undef VEC_OPEQ 

    // todo try and add slices later, for a reference version of get
    template<size_t... idx>
    auto get() const -> vec<T, sizeof...(idx)> {
        static_assert((... && (idx < N)));

        constexpr size_t new_len = sizeof...(idx);
        vec<T, new_len> v;

        size_t jdx = 0;
        ((v[jdx++] = vals[idx]), ...);

        return v;
    }

    template<size_t... idx, typename TT, size_t M>
    vec& setv(vec<TT, M> const& other) {
        static_assert(
            sizeof...(idx) == M,
            "invalid number of parameters passed to vec.set"
        );
        static_assert((... && (idx < N)));

        size_t jdx = 0;
        ((vals[idx] = other[jdx++]), ...);

        return *this;
    }

    template<size_t... idx, typename... new_vals>
    // soon: requires(sizeof...(idx) == sizeof...(new_vals))
    vec& set(new_vals&&... values) {
        static_assert(
            sizeof...(idx) == sizeof...(new_vals),
            "invalid number of parameters passed to vec.set"
        );
        static_assert((... && (idx < N)));

        ((vals[idx] = values), ...);

        return *this;
    }

    template<typename... Extra>
    auto extend(Extra... extras) -> vec<T, N + sizeof...(Extra)> {
        vec<T, N + sizeof...(Extra)> v;

        // copy over first N values from current vec
        unroll<N>([&, this](auto i) {
            v[i] = vals[i];
        });

        // add the last sizeof...(Extra) values to the end of the new vec
        size_t idx = 0;
        ((v[idx++ + N] = extras), ...);

        return v;
    }

    T dot(vec const& other) const {
        T total = 0;
        unroll<N>([&, this](auto i) {
            total += vals[i] * other[i];
        });
        return total;
    }

    vec round() const {
        vec rounded;
        unroll<N>([&, this](auto i) {
            rounded[i] = std::round(vals[i]);
        });
        return rounded;
    }

    vec sqrt() const {
        vec w;
        unroll<N>([&, this](auto i) {
            w[i] = std::sqrt(vals[i]);
        });
        return w;
    }

    vec clamp(T min, T max) const {
        vec w;
        unroll<N>([&, this](auto i) {
            w[i] = std::clamp(vals[i], min, max);
        });
        return w;
    }

    T sum() const {
        T total = T();
        unroll<N>([&, this](auto i) {
            total += vals[i];
        });
        return total;
    }

    void normalize() {
        *this /= sum();
    }

    // applies a vector of conditional assignments
    vec& movc(vec<bool, N> cond, vec values) {
        unroll<N>([&, this](auto i) {
            if(cond[i]) vals[i] = values.vals[i];
        });
        return *this;
    }

    static T dot(vec const& v1, vec const& v2) {
        T total = 0;
        unroll<N>([&](auto i) {
            total += v1[i] * v2[i];
        });
        return total;
    }

    static vec abs(vec const& v) {
        vec vabs;
        unroll<N>([&](auto i) { vabs[i] = std::abs(v[i]); });
        return vabs;
    }

    static vec max(vec const& v1, vec const& v2) {
        vec w;
        unroll<N>([&](auto i) { w[i] = std::max(v1[i], v2[i]); });
        return w;
    }
    // todo add generic element-wise and cumulative math operations
    // e.g., {0,1,2}.max() == 2, etc.

    // w >= v ? 1 : 0
    static vec step(vec const& v, vec const& w) {
        vec stepped;
        unroll<N>([&](auto i) { stepped[i] = w[i] >= v[i] ? 1 : 0; });
        return stepped;
    }

    static vec step(T v, vec const& w) {
        vec stepped;
        unroll<N>([&](auto i) { stepped[i] = w[i] >= v ? 1 : 0; });
        return stepped;
    }

    static vec lerp(float t, vec const& from, vec const& to) {
        vec lerped;
        unroll<N>([&](auto i) { lerped[i] = (to[i] - from[i]) * t + from[i]; });
        return lerped;
    }

    template<typename TT, size_t NN>
    friend std::ostream& operator<<(std::ostream& out, vec<TT, NN> v);
};

template<typename T, size_t N>
std::ostream& operator<<(std::ostream& out, vec<T, N> v) {
    std::cout << "{ ";
    for(size_t i = 0; i < N-1; i++)
        std::cout << v[i] << ", ";
    std::cout << v[N-1] << " }";
    return out;
}

template<typename T, typename... Args>
vec(T v, Args&&... args) -> vec<T, sizeof...(Args)+1>;

#define SCALAR_OP(op) \
template<typename TT, typename VT, size_t M> \
vec<VT, M> operator op (vec<VT, M> const& v, TT const& val) { \
    vec<VT, M> w; \
    unroll<M>([&](auto i) { w.vals[i] = v.vals[i] op val; }); \
    return w; \
} \
template<typename TT, typename VT, size_t M> \
vec<VT, M> operator op (TT const& val, vec<VT, M> const& v) { \
    vec<VT, M> w; \
    unroll<M>([&](auto i) { w.vals[i] = val op v.vals[i]; }); \
    return w; \
}
SCALAR_OP(+)
SCALAR_OP(-)
SCALAR_OP(*)
SCALAR_OP(/)
#undef SCALAR_OP

#define VEC_OP(op) \
template<typename T1, typename T2, size_t M> \
auto operator op (vec<T1, M> const& v1, vec<T2, M> const& v2) \
    -> vec<std::decay_t<decltype(T1() op T2())>, M> { \
    vec<std::decay_t<decltype(T1() op T2())>, M> w; \
    unroll<M>([&](auto i) { w.vals[i] = v1.vals[i] op v2.vals[i]; }); \
    return w; \
}
VEC_OP(+)
VEC_OP(-)
// even though this may make no sense in the lin.alg. world, here we just assume that all
// vector operators are element-wise
VEC_OP(*)
VEC_OP(/)
#undef VEC_OP


typedef vec<bool, 2> bool2;
typedef vec<bool, 3> bool3;
typedef vec<bool, 4> bool4;

typedef vec<float, 2> float2;
typedef vec<float, 3> float3;
typedef vec<float, 4> float4;

typedef vec<int, 2> int2;
typedef vec<int, 3> int3;
typedef vec<int, 4> int4;

