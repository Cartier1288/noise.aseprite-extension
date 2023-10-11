#include "worley.h"

#include "utils.h"
#include "larray.h"

#include <string>
#include <assert.h>

DECLARE_LUA_CLASS_NAMED(Worley, Worley);


#define GET_IDX(x, y) ((y)*width + (x))

size_t Worley::get_result_size() const { return width*height; }

void Worley::compute(double values[]) const {
    size_t indices = get_result_size();
    for(int i = 0; i < indices; i++) {
        values[i] = i+1;
    }
}

Worley::result_t Worley::compute() const {
    result_t values(get_result_size());
    
    compute(values.data());

    return values;
}

// could use try_get_num_field, but this is faster and less verbose :)
#define GET_NUMBER(field, key) \
    if(lua_getfield(L, idx, #key) != LUA_TNIL) { \
        W.field = luaL_checknumber(L, -1); \
        lua_pop(L, 1); \
    }
#define GET_INTEGER(field, key) \
    if(lua_getfield(L, idx, #key) != LUA_TNIL) { \
        W.field = luaL_checkinteger(L, -1); \
        lua_pop(L, 1); \
    }
#define GET_ENUM(ENUM, enum_last, field, key) \
    if(lua_getfield(L, idx, #key) != LUA_TNIL) { \
        int val = luaL_checkinteger(L, -1); \
        if(val < 0 || val >= enum_last) \
            luaL_error(L, "invalid enum value passed as field"); \
        W.field = (ENUM) val; \
        lua_pop(L, 1); \
    }
int Worley::lnew(lua_State* L) {
    Worley W; // start off default initialized, fill in as we go

    int idx = 1;

    if(lua_istable(L, idx)) {
        GET_NUMBER(width, width);
        GET_NUMBER(height, height);
        GET_INTEGER(length, length);

        GET_NUMBER(mean_points, mean_points);
        GET_NUMBER(n, n);
        GET_NUMBER(cellsize, cellsize);
        GET_ENUM(DISTANCE_FUNC, DISTANCE_LAST, distance_func, distance_func);

        GET_NUMBER(movement, movement);
        GET_ENUM(INTERPOLATE_FUNC, INTERPOLATE_LAST, movement_func, movement_func);
    }
    else if (lua_gettop(L) > 0) {
        luaL_error(L, "invalid argument passed to Worley constructor");
    }

    // copy our constructed Worley object into a userdata 
    push_new<Worley>(L, W);

    // return Worley userdata object
    return 1;
}
#undef GET_ENUM
#undef GET_INTEGER
#undef GET_NUMBER


int Worley::compute(lua_State* L) {
    Worley* worley = get_obj<Worley>(L, 1);

    lua_getglobal(L, "ldarray");

    int size = worley->get_result_size();

    // add ldarray size argument to stack
    lua_pushinteger(L, size);

    // call ldarray constructor
    if(lua_pcall(L, 1, 1, 0) != LUA_OK)
        return 0;

    auto arr = get_obj<larray<double>>(L, -1);

    // sanity check
    LASSERT(
        arr->size == worley->get_result_size(), 
        "unexpected error, array size differs from Worley"
    );

    // compute directly on top of the ldarray values
    worley->compute(arr->values);

    // return ldarray
    return 1;
}

void Worley::register_class(lua_State* L) {
    static const luaL_Reg methods[] = {
        { "compute", Worley::compute },
        { nullptr, nullptr }
    };

    REG_LUA_CLASS(L, Worley, methods);
    REG_LUA_CNSTR(L, Worley, Worley::lnew);
}