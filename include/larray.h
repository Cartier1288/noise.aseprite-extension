#pragma once

#include "common.h"
#include "utils.h"

#include <array>

// Lua dedicated array

template<typename T>
struct larray {
    size_t size;
    T values[1];

    larray(size_t size) : size(size) {}

    // gets assigned directly to larray{}
    static int lnew(lua_State* L);
    static int gc(lua_State* L);

    static int set(lua_State* L);
    static int get(lua_State* L);
    static int getsize(lua_State* L);

    static void register_class(lua_State* L);
};

template<typename T>
int larray<T>::lnew(lua_State* L) {

    int idx = 1;

    // just grab the length and allocate the user data to fill to the end of the array
    size_t len = luaL_checknumber(L, idx);

    // note: (len-1) is used here, since larray is declared with values[1] (e.g., sizeof(larray) 
    // already takes one value into account)
    push_new_offset<larray<T>>(L, (len-1)*sizeof(T), len);

    return 1;
}

template<typename T>
int larray<T>::gc(lua_State* L) {
    get_obj<larray<T>>(L, 1)->~larray();
    return 0;
}

template<typename T>
int larray<T>::getsize(lua_State* L) {
    larray<T>* arr = get_obj<larray<T>>(L, 1);

    luaL_argcheck(L, arr != nullptr, 1, "'larray<T>' expected");

    lua_pushinteger(L, arr->size);

    return 1;
}

template<typename T>
void larray<T>::register_class(lua_State* L) {
    static const luaL_Reg larray_methods[] = {
        { "__gc", larray<T>::gc },
        // { "set", larray<T>::set },
        { "__newindex", larray<T>::set },
        // { "get", larray<T>::get },
        { "__index", larray<T>::get },
        // { "size", larray<T>::getsize },
        { "__len", larray<T>::getsize },
        { nullptr, nullptr }
    };

    REG_LUA_CLASS(L, larray<T>, larray_methods);
    REG_LUA_CNSTR(L, larray<T>, larray<double>::lnew);
}