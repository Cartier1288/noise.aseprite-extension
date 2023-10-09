#include "noise.h"

#include <iostream>
#include <vector>

#include "common.h"

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

static int l_worley(lua_State* L) {

  int length = 1;

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
  return 1;
}
