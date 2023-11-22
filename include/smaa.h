#pragma once

#include "common.h"
#include "ibuffer.h"

class SMAA {    
public:
    enum STEPS {
        EDGES=1, WEIGHTS, BLENDING
    };

    SMAA();

    ibuffer4 apply(fbuffer4 orig_buffer);
};

int l_SMAA(lua_State* L);