#include "noise.h"

#include <iostream>
#include <vector>

#include "common.h"
#include "worley.h"
#include "larray.h"
#include "math_utils.h"

static int l_print(lua_State* L) {
  std::cout << "Hello, World!" << std::endl;
  return 0;
}

// mostly just a test function to make sure dynamic linking is working
static int l_sum(lua_State* L) {
  int args = lua_gettop(L);

  if(args == 0) {
    lua_pushnumber(L, 0.0);
    return 1;
  }

  double total = 0.0;

  // check if its an array
  if(args == 1 && lua_istable(L, 1)) {
    int args = luaL_len(L, 1);

    for(int i = 1; i <= args; i++) {
      lua_geti(L, 1, i);

      double val = luaL_checknumber(L, -1);
      total += val;

      lua_pop(L, 1);
    }

    lua_pushnumber(L, total);

    return 1;
  }

  // sum operands directly
  for(int i = 1; i <= args; i++) {
    double val = luaL_checknumber(L, i);
    total += val;
  }

  lua_pushnumber(L, total);

  return 1;
}




// function that generates a series of snapshots of size width x height of the Worley pseudo-random
// number generator
// args:
//  [1] seed: int
//  [2] width: int
//  [3] height: int
//  [4] length: int
//  [5] options: table
static int l_worley(lua_State* L) {

  int argc = lua_gettop(L);

  if(argc < 4) {
    luaL_error(L, "too few arguments passed to Worley function, requires at least ");
    return 0;
  }

  int seed = luaL_checknumber(L, 1);
  int width = luaL_checknumber(L, 2);
  int height = luaL_checknumber(L, 3);
  int length = luaL_checknumber(L, 4);

  if(argc >= 5) luaL_checktype(L, 5, LUA_TTABLE);

  std::vector<std::vector<double>> values(length);

  for(int frame = 0; frame < length; frame++) {
    
  }


  return 1;
}

static const struct luaL_Reg mylib[] = {
  {"print", l_print},
  {"sum", l_sum},
  {nullptr, nullptr}
};

int luaopen_libnoise(lua_State* L) {
  luaL_newlib(L, mylib);

  // libnoise.DISFUNCS
  lua_newtable(L);
  for(size_t i = EUCLIDIAN; i < DISTANCE_LAST; i++) {
    lua_pushinteger(L, i);
    lua_setfield(L, -2, DISTANCE_FUNC_NAMES[i]);
  }

  lua_setfield(L, -2, "DISFUNCS");

  // push classes into the global namespace ...
  larray<double>::register_class(L);

  return 1;
}
