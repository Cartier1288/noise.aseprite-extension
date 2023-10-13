#pragma once

#include "utils.h"

#include <array>
#include <limits>

template<typename T, size_t L>
class isort;

template<typename T, size_t L>
class isort {
    std::array<T, L> values;

public:
    isort() {
        constexpr_for<0, L, 1>([this](auto i) {
            values[i] = std::numeric_limits<T>::max();
        });
    }

    void insert(T val) {
        constexpr_for<0, L, 1>([this, val](auto i) {
            if(val < values[i]) {
                for(size_t j = L-1; j > i; j--) {
                    values[j] = values[j-1];
                }
                values[i] = val;
            }
        });
    }

    std::array<T, L> const& get_values() const {
        return values;
    }
};


// == isort<T,1> specialization ===
template<typename T>
class isort<T, 1> {
    std::array<T,1> value;

public:
    isort() {
        value[0] = std::numeric_limits<T>::max();
    }

    void insert(T val) {
        if(val < value[0]) value[0] = val;
    }
    std::array<T, 1> const& get_values() const {
        return value;
    }
};

// == isort<T,2> specialization ===
template<typename T>
class isort<T, 2> {
    std::array<T,2> values;

public:
    isort() {
        constexpr_for<0, 2, 1>([this](auto i) {
            values[i] = std::numeric_limits<T>::max();
        });
    }

    void insert(T val) {
        if(val < values[0]) {
            values[1] = values[0];
            values[0] = val;
        }
        else if(val < values[1]) {
            values[1] = val;
        }
    }
    std::array<T, 2> const& get_values() const {
        return values;
    }
};

// == isort<T,3> specialization ===
template<typename T>
class isort<T, 3> {
    std::array<T,3> values;

public:
    isort() {
        constexpr_for<0, 3, 1>([this](auto i) {
            values[i] = std::numeric_limits<T>::max();
        });
    }

    void insert(T val) {
        if(val < values[0]) {
            values[2] = values[1];
            values[1] = values[0];
            values[0] = val;
        }
        else if(val < values[1]) {
            values[2] = values[1];
            values[1] = val;
        }
        else if(val < values[2]) {
            values[2] = val;
        }
    }
    std::array<T, 3> const& get_values() const {
        return values;
    }
};
