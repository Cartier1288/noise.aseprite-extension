#include "worley.h"

#include "utils.h"
#include "larray.h"
#include "lattice3.h"

#include <string>
#include <assert.h>
#include <math.h>
#include <cmath>
#include <random>

DECLARE_LUA_CLASS_NAMED(Worley, Worley);


#define GET_IDX(x, y) ((y)*width + (x))

size_t Worley::get_result_size() const { return width*height; }

static unsigned int gen_points(unsigned int seed, double mean, double min, double max) {
    std::mt19937 gen(seed);
    std::poisson_distribution<> d(mean);
    return d(gen);
}

void Worley::compute_frame(double z, double values[]) const {
    std::mt19937 gen;
    std::poisson_distribution<> d(mean_points);

    lattice3 ltc(cellsize, freq);
    ltc.set_seed(seed);

    // todo: make a hashgrid to store points, because generating points with Poisson is HEAVY

    size_t indices = get_result_size();
    for(unsigned int y = 0; y < height; y++) {
        size_t scanned = y * width;
        for(unsigned int x = 0; x < width; x++) {
            auto grid_seed = ltc.get_seed(x, y, z);
            gen.seed(grid_seed);
            values[scanned+x] = d(gen);//gen_points(grid_seed, mean_points, 1, mean_points*9);
        }
    }
}

Worley::result_t Worley::compute_frame(double z) const {
    result_t values(get_result_size());
    
    compute_frame(z, values.data());

    return values;
}

// could use try_get_num_field, but this is faster and less verbose :)
#define GET_NUMBER(idx, field, key) \
    if(lua_getfield(L, idx, #key) != LUA_TNIL) { \
        W.field = luaL_checknumber(L, -1); \
        lua_pop(L, 1); \
    }
#define GET_INTEGER(idx, field, key) \
    if(lua_getfield(L, idx, #key) != LUA_TNIL) { \
        W.field = luaL_checkinteger(L, -1); \
        lua_pop(L, 1); \
    }
#define GET_ENUM(idx, ENUM, enum_last, field, key) \
    if(lua_getfield(L, idx, #key) != LUA_TNIL) { \
        int val = luaL_checkinteger(L, -1); \
        if(val < 0 || val >= enum_last) \
            luaL_error(L, "invalid enum value passed as field"); \
        W.field = (ENUM) val; \
        lua_pop(L, 1); \
    }
int Worley::lnew(lua_State* L) {
    Worley W; // start off default initialized, fill in as we go
    W.seed = std::random_device()(); // default init seed if there in case none is given

    int idx = 1;

    if(lua_istable(L, idx)) {
        GET_NUMBER(idx, width, width);
        GET_NUMBER(idx, height, height);
        GET_INTEGER(idx, length, length);

        GET_NUMBER(idx, mean_points, mean_points);
        GET_NUMBER(idx, n, n);
        GET_NUMBER(idx, cellsize, cellsize);
        GET_ENUM(idx, DISTANCE_FUNC, DISTANCE_LAST, distance_func, distance_func);

        GET_NUMBER(idx, movement, movement);
        GET_ENUM(idx, INTERPOLATE_FUNC, INTERPOLATE_LAST, movement_func, movement_func);

        GET_INTEGER(idx, seed, seed);

        if(lua_getfield(L, idx, "loops")) {
            bool is_table = lua_istable(L, -1);
            luaL_argexpected(L, is_table, idx, "expected table of form {x,y,z}");

            // make sure we were given a table !!
            if(!is_table) return 0;

            GET_NUMBER(-1, freq.x, x);
            GET_NUMBER(-1, freq.y, y);
            GET_NUMBER(-1, freq.z, z);

            lua_pop(L, 1);
        }
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

    lua_createtable(L, worley->length, 0);

    erp_func_t mfun = interpolate_funcs[worley->movement_func];

    double z = 0.0;
    double t = 0.0;
    double t_inc = 1.0 / (double)worley->length;
    for(double frame = 0; frame < worley->length; frame++) {
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
        worley->compute_frame(z, arr->values);

        lua_seti(L, -2, frame+1);

        // move further in
        t += t_inc;
        z += mfun(0.0, worley->movement, t);
    }

    // return ldarray[]
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