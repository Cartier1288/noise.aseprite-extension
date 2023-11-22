#include "ibuffer.h"

#include <assert.h>

int main(int argc, char** argv) {
    ibuffer<int, 4> buffer(192, 192, int4{0});
    return 0;
}