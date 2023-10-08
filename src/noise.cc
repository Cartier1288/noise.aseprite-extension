#include "noise.h"

#include <iostream>

#include "common.h"

static int l_print(lua_State* L) {
  std::cout << "Hello, World!" << std::endl;
  return 0;
}

static const struct luaL_Reg mylib[] = {{"print", l_print}, {nullptr, nullptr}};

int luaopen_libnoise(lua_State* L) {
  luaL_newlib(L, mylib);
  return 1;
}
