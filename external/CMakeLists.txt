# build shared Lua library
add_library(lua SHARED
    lua/lapi.c
    lua/lcode.c
    lua/lctype.c
    lua/ldebug.c
    lua/ldo.c
    lua/ldump.c
    lua/lfunc.c
    lua/lgc.c
    lua/llex.c
    lua/lmem.c
    lua/lobject.c
    lua/lopcodes.c
    lua/lparser.c
    lua/lstate.c
    lua/lstring.c
    lua/ltable.c
    lua/ltm.c
    lua/lundump.c
    lua/lvm.c
    lua/lzio.c
    lua/ltests.c)
  add_library(lauxlib lua/lauxlib.c)
  add_library(lualib
    lua/lbaselib.c
    lua/lcorolib.c
    lua/ldblib.c
    lua/linit.c
    lua/liolib.c
    lua/lmathlib.c
    lua/loadlib.c
    lua/loslib.c
    lua/lstrlib.c
    lua/ltablib.c
    lua/lutf8lib.c)
  target_compile_definitions(lua PUBLIC LUA_FLOORN2I=1)
  target_compile_definitions(lualib PRIVATE HAVE_SYSTEM)
  target_include_directories(lua PUBLIC lua)
  target_include_directories(lauxlib PUBLIC lua)
  target_include_directories(lualib PUBLIC lua)
  target_link_libraries(lauxlib lua)