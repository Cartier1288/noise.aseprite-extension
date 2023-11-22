set(INCLUDE_PATH "${CMAKE_SOURCE_DIR}/include")
set(SOURCE_PATH "${CMAKE_SOURCE_DIR}/src")

file(GLOB_RECURSE MY_SOURCES
  "main.cc"
)
file(GLOB_RECURSE MY_HEADERS
  "${INCLUDE_PATH}/*.h"
)

set(TEST_EXEC noiselua)

add_executable(${TEST_EXEC} ${MY_SOURCES}) 

set_target_properties(${TEST_EXEC} PROPERTIES 
  ${TEST_EXEC} "noiselua"
)
#set_target_properties(${TEST_EXEC} PROPERTIES PUBLIC_HEADER ${MY_HEADERS})

target_link_libraries(${TEST_EXEC} PRIVATE lua lauxlib lualib)

target_include_directories(${TEST_EXEC} PRIVATE "${INCLUDE_PATH}")

# external includes
target_include_directories(${TEST_EXEC} PRIVATE "${PROJECT_SOURCE_DIR}/external/lua")

# note we neither link nor build Lua here since it is already linked to Aseprite

set(TEST_INSTALL_DIR "${CMAKE_SOURCE_DIR}/tests/bin")

install(TARGETS ${TEST_EXEC}
  LIBRARY DESTINATION "${TEST_INSTALL_DIR}"
  RUNTIME DESTINATION "${TEST_INSTALL_DIR}"
)

add_subdirectory(ctests)