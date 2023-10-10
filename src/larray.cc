#include "larray.h"

DECLARE_LUA_CLASS_NAMED(larray<double>, ldarray)

template<>
int larray<double>::set(lua_State* L) {
    larray<double>* arr = get_obj<larray<double>>(L, 1);
    int idx = (int)luaL_checkinteger(L, 2) - 1;
    
    luaL_argcheck(L, arr != nullptr, 1, "'larray<double>' expected");
    luaL_argcheck(L, 0 <= idx && idx < arr->size, 2, "index out of range");
    luaL_checkany(L, 3);

    // the reason this function is specialized is exactly because of this, can't really generalize
    // this part ...
    double val = luaL_checknumber(L, 3);
    arr->values[idx] = val;

    return 0;
}

template<>
int larray<double>::get(lua_State* L) {
    larray<double>* arr = get_obj<larray<double>>(L, 1);
    int idx = (int)luaL_checkinteger(L, 2) - 1;

    luaL_argcheck(L, arr != nullptr, 1, "'larray<double>' expected");
    luaL_argcheck(L, 0 <= idx && idx < arr->size, 2, "index out of range");

    lua_pushnumber(L, arr->values[idx]);

    return 1;
}