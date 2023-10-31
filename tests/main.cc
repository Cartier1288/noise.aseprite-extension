
// NOTE: this test exec is _meant_ to be run from within the /tests/ folder,
// relative paths to the scripts and dynamic library may not work correctly
// otherwise

#include "common.h"
#include "utils.h"

#include <vector>
#include <tuple>
#include <unordered_map>
#include <string>
#include <exception>
#include <filesystem>
#include <iostream>
#include <stdio.h>

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

std::tuple<std::string, std::string>
parse_param(std::string arg) {

  auto it = arg.begin();

  size_t eq_idx = arg.find("=");
  if(eq_idx == std::string::npos)
    throw std::runtime_error("incorrect argument format, expected parameters in like param=value");

  size_t param_size = eq_idx;
  size_t value_size = arg.size()-eq_idx-1;

  std::string param; param.reserve(eq_idx); param.resize(eq_idx);
  std::string value; value.reserve(value_size); value.resize(value_size);

  char c;

  auto param_it = param.begin();
  while((c = *it) != '=') {
    *param_it = c;

    param_it++;
    it++;
  }

  auto value_it = value.begin();
  while(++it != arg.end()) {
    *value_it = *it;
    value_it++;
  }

  return {param, value};
}


std::unordered_map<std::string, std::string> params;
std::filesystem::path folder;
std::vector<std::string> files;

int main(int argc, char** argv) {

  if (argc < 3) {
    std::cerr
        << "too few arguments; usage: `noiselua [--param key=value,...] [--directory scripts_folder] file [file,]`"
        << std::endl;
    return 1;
  }

  // parse arguments
  size_t arg_idx = 1;
  std::string arg;

  auto try_inc = [&](std::string err, size_t inc = 1) {
    if(arg_idx + inc < argc) {
      arg_idx += inc;
      arg = argv[arg_idx];
    }
    else {
      throw std::runtime_error{err};
    }
  };

  for(; arg_idx < argc; arg_idx++) {
    arg = argv[arg_idx];

    if(arg == "-p" || arg=="--param") {
      try_inc("too few arguments to -d/--directory");

      auto kv = parse_param(arg);
      params.emplace(std::get<0>(kv), std::get<1>(kv));
    }
    else if(arg == "-d" || arg == "--directory") {
      try_inc("too few arguments to -p/--param");
      folder = arg;
    }
    else { // treat every other argument like a file 
      files.push_back(arg);
    }
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

  // register app and app.params tables
  lua_createtable(L, 0, 0); // app

  lua_pushstring(L, "params");
  lua_createtable(L, 0, 0); // app.params
  
  lua_settable(L, -3);

  lua_setglobal(L, "app");

  // assign paramaters to global `app`
  lua_getglobal(L, "app");
  lua_getfield(L, -1, "params");
  for(auto& kv : params) {
    lua_pushstring(L, kv.second.c_str());
    lua_setfield(L, -2, kv.first.c_str());
  }
  lua_pop(L, 2);

  // push internal Lua error handler
  lua_pushcfunction(L, l_handle_error);

  bool errored = false;

  for (auto& basename : files) {
    std::filesystem::path file = folder / basename;
    file.replace_extension(".lua"); // add a .lua if it isn't already there

    std::cout << "== loading file: " << file << std::endl;

    int error =
        luaL_loadfile(L, file.string().c_str()) || lua_pcall(L, 0, 0, -2);
    if (error) {
      errored = true;
      std::cerr << lua_tostring(L, -1) << std::endl;
      lua_pop(L, 1);
    }

    std::cout << "== done running file: " << file
              << ", status: " << (error ? "FAIL" : "SUCCESS") << std::endl
              << std::endl;
  }

  lua_close(L);

  return errored ? 1 : 0;
}
