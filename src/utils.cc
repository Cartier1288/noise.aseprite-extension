#include "utils.h"

#include <iostream>
#include <assert.h>

void dump_stack(lua_State* L) {
    int top = lua_gettop(L);

    for(int i = 1; i <= top; i++) {
        int t = lua_type(L, i);

        switch(t) {
            case LUA_TSTRING: {
                std::cout << "'" << lua_tostring(L, i) << "'";
                break;
            }
            case LUA_TBOOLEAN: {
                std::cout << lua_toboolean(L, i) ? "true" : "false";
                break;
            }
            case LUA_TNUMBER: {
                std::cout << lua_tonumber(L, i);
                break;
            }
            default: {
                std::cout << lua_typename(L, t);
                break;
            }
        }
        std::cout << " ";
    }
    std::cout << std::endl;
}