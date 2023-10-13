
// NOTE: this test exec is _meant_ to be run from within the /tests/ folder,
// relative paths to the scripts and dynamic library may not work correctly
// otherwise

#include "common.h"
#include "utils.h"

#include <filesystem>
#include <iostream>

static const char mt_index_code[] =
    "__generic_mt_index = function(t, k) "
    "  local mt = getmetatable(t) "
    "  local f = mt[k] "
    "  if f then return f end "
    "  f = mt.__getters[k] "
    "  if f then return f(t) end "
    "  if type(t) == 'table' then return rawget(t, k) end "
    "  error(debug.traceback()..': Field '..tostring(k)..' does not exist')"
    "end "
    "__generic_mt_newindex = function(t, k, v) "
    "  local mt = getmetatable(t) "
    "  local f = mt[k] "
    "  if f then return f end "
    "  f = mt.__setters[k] "
    "  if f then return f(t, v) end "
    "  if type(t) == 'table' then return rawset(t, k, v) end "
    "  error(debug.traceback()..': Cannot set field '..tostring(k))"
    "end";

int l_handle_error(lua_State* L) {
  const char* msg = lua_tostring(L, -1);
  luaL_traceback(L, L, msg, 2);
  lua_remove(L, -2);
  return 1;
}

void handle_error() {}

int main(int argc, char** argv) {

  if (argc < 3) {
    std::cerr
        << "too few arguments; usage: `noiselua scripts_folder file [file,]`"
        << std::endl;
    return 1;
  }

  lua_State* L = luaL_newstate();
  luaL_openlibs(L);

  // add noise library scripts to path
  luaL_dostring(L, "package.path = \"../scripts/?.lua;\" .. package.path");
  luaL_dostring(L, "package.cpath = \"../bin/?.so;\" .. package.cpath");
  luaL_dostring(L, "package.cpath = \"../bin/?.a;\" .. package.cpath");
  luaL_dostring(L, "package.cpath = \"../bin/?.dll;\" .. package.cpath");

  // use the same indexing functions that aseprite uses
  luaL_dostring(L, mt_index_code);

  std::filesystem::path folder = argv[1];

  // push internal Lua error handler
  lua_pushcfunction(L, l_handle_error);

  for (size_t i = 2; i < argc; i++) {
    std::filesystem::path file = folder / argv[i];
    file.replace_extension(".lua"); // add a .lua if it isn't already there

    std::cout << "== loading file: " << file << std::endl;

    int error =
        luaL_loadfile(L, file.string().c_str()) || lua_pcall(L, 0, 0, -2);
    if (error) {
      std::cerr << lua_tostring(L, -1) << std::endl;
      lua_pop(L, 1);
    }

    std::cout << "== done running file: " << file
              << ", status: " << (error ? "FAIL" : "SUCCESS") << std::endl
              << std::endl;
  }

  lua_close(L);

  return 0;
}
