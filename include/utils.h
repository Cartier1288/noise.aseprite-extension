#pragma once

#include "common.h"

#define REG_ARRAY()

template<typename T>
void assign_array(T arr[], size_t len) {

}

// prints stack from the bottom up
void dump_stack(lua_State* L);
