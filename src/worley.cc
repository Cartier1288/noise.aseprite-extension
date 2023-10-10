#include "worley.h"

#include "utils.h"
#include "larray.h"

#include <string>
#include <assert.h>

DECLARE_LUA_CLASS_NAMED(Worley, Worley);


#define GET_IDX(x, y) ((y)*width + (x))

size_t Worley::get_result_size() const { return width*height; }

void Worley::compute(double values[]) const {}

Worley::result_t Worley::compute() const {
    result_t values(get_result_size());
    
    compute(values.data());

    return values;
}



int Worley::compute(lua_State* L) {
    Worley* worley = get_obj<Worley>(L, 1);

    lua_getglobal(L, "ldarray");

    int size = 123;

    // add ldarray size argument to stack
    lua_pushinteger(L, size);

    // call ldarray constructor
    if(lua_pcall(L, 3, 1, 0) != LUA_OK)
        return 0;

    auto arr = get_obj<larray<double>>(L, -1);

    // sanity check
    assert(arr->size == worley->get_result_size());

    // compute directly on top of the ldarray values
    worley->compute(arr->values);

    // return ldarray
    return 1;
}
