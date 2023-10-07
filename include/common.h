#pragma once

// pretty sure since we aren't linking Lua, extern isn't necessary ... but wtv
extern "C" {
#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"
}
