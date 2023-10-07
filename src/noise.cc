#include "noise.h"

#include "common.h"

static int l_print(lua_State* L) { return 0; }

static const struct luaL_Reg mylib[] = {{"print", l_print}, {nullptr, nullptr}};

int luaopen_mylib(lua_State* L) {
  luaL_newlib(L, mylib);
  return 1;
}
