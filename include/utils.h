#pragma once

#include "common.h"

#include <assert.h>
#include <typeinfo>
#include <utility>


#define LASSERT(assertion, msg) \
    if(!(assertion)) { luaL_error(L, msg); return 0; }

// prints stack from the bottom up
void dump_stack(lua_State* L);

// some of these helper functions are taken from src/app/script/luacpp.h in the aseprite source
// code

template<typename T>
const char* get_classname();

#define DECLARE_LUA_CLASS(T) \
    template<> const char* get_classname<T>() { return #T; }

// if a name other than the type name should be used (used for generics, like larray<double>)
#define DECLARE_LUA_CLASS_NAMED(T, Name) \
    template<> const char* get_classname<T>() { return #Name; }

#define DECLARE_LUA_CLASS_ALIAS(T, ALIAS) \
    template<> const char* get_classname<ALIAS>() { return #T; }


// gets the user data associated with a class declared using DECLARE_LUA_CLASS from the stack at
// index idx
template<typename T>
T* get_obj(lua_State* L, int idx) {
    T* ptr = (T*) luaL_checkudata(L, idx, get_classname<T>());
    assert(typeid(*ptr) == typeid(T));
    return ptr;
}

// constructs a new class of type T at the address of the user data allocated by lua and returns it
template<typename T, typename... Args>
T* push_new(lua_State* L, Args&&... args) {
    T* addr = (T*) lua_newuserdata(L, sizeof(T));
    new (addr) T(std::forward<Args>(args)...);
    luaL_getmetatable(L, get_classname<T>());
    lua_setmetatable(L, -2);
    return addr;
}

// same as push_new but adds an extra offset to the end of the user data in case of dynamic size
template<typename T, typename... Args>
T* push_new_offset(lua_State* L, size_t offset, Args&&... args) {
    T* addr = (T*) lua_newuserdata(L, sizeof(T) + offset);
    new (addr) T(std::forward<Args>(args)...);
    luaL_getmetatable(L, get_classname<T>());
    lua_setmetatable(L, -2);
    return addr;
}

// L is lua state, T is type associated with lua userdata
#define REG_LUA_CLASS(L, T, methods) { \
    luaL_newmetatable(L, get_classname<T>()); \
    lua_getglobal(L, "__generic_mt_index"); \
    lua_setfield(L, -2, "__index"); \
    lua_getglobal(L, "__generic_mt_newindex"); \
    lua_setfield(L, -2, "__newindex"); \
    luaL_setfuncs(L, methods, 0); \
    lua_pop(L, 1); \
}

// register the name of the class to the C function that creates a new instance of it
#define REG_LUA_CNSTR(L, T, cnstr) { \
    lua_pushcfunction(L, cnstr); \
    lua_setglobal(L, get_classname<T>()); \
}

// registers the properties of a given class
#define REG_LUA_PROPERTIES(L, T, properties) { \
    luaL_getmetatable(L, get_classname<T>()); \
    create_mt_getters_setters(L, get_classname<T>(), properties); \
    lua_pop(L, 1); \
}

template<typename T>
void try_get_num_field(lua_State* L, T& store, int idx, int stack, const char* key) {
    if(lua_getfield(L, idx, key) != LUA_TNIL) {
        store = luaL_checknumber(L, stack);
        lua_pop(L, 1);
    }
}