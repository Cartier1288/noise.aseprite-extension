
// NOTE: this test exec is _meant_ to be run from within the /tests/ folder, relative paths to the
// scripts and dynamic library may not work correctly otherwise

#include "common.h"
#include "utils.h"

#include <iostream>
#include <filesystem>

int main(int argc, char** argv) {

    if(argc < 3) {
        std::cerr << "too few arguments; usage: `noiselua scripts_folder file [file,]`" 
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

    std::filesystem::path folder = argv[1];

    for(size_t i = 2; i < argc; i++) {
        std::filesystem::path file = folder / argv[i];
        file.replace_extension(".lua"); // add a .lua if it isn't already there

        std::cout << "== loading file: " << file << std::endl;

        int error = luaL_dofile(L, file.string().c_str());
        if(error) {
            std::cerr << lua_tostring(L, -1) << std::endl;
            lua_pop(L, 1);
        }

        std::cout << "== done running file: " << file
                  << ", status: " << (error ? "FAIL" : "SUCCESS")
                  << std::endl << std::endl;
    }

    lua_close(L);

    return 0;
}