set(INCLUDE_PATH "${CMAKE_SOURCE_DIR}/include")
set(SOURCE_PATH "${CMAKE_SOURCE_DIR}/src")

file(GLOB_RECURSE MY_SOURCES
  "${SOURCE_PATH}/*.cc"
)
file(GLOB_RECURSE MY_HEADERS
  "${INCLUDE_PATH}/*.h"
)

#add_executable(${NOISE_LIB} ${MY_SOURCES}) 
add_library(${NOISE_LIB} SHARED ${MY_SOURCES})

set_target_properties(${NOISE_LIB} PROPERTIES 
  OUTPUT_NAME "${NOISE_LIB_NAME}"
)
#set_target_properties(${NOISE_LIB} PROPERTIES PUBLIC_HEADER ${MY_HEADERS})

# note that the dynamic library is actually linked with lauxlib and lualib statically, since
# I couldn't find a way to get it to work with aseprite's lua symbols out of the box
target_link_libraries(${NOISE_LIB} PRIVATE lauxlib lualib)

target_include_directories(${NOISE_LIB} PRIVATE "${INCLUDE_PATH}")

# external includes
target_include_directories(${NOISE_LIB} PRIVATE "${PROJECT_SOURCE_DIR}/external/lua")

# note we neither link nor build Lua here since it is already linked to Aseprite

install(TARGETS ${NOISE_LIB}
  LIBRARY DESTINATION "${INSTALL_DIR}"
  RUNTIME DESTINATION "${INSTALL_DIR}"
)
