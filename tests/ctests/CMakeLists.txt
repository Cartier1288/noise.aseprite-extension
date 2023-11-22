project(NoiseTests)

include(CTest)

set(INCLUDE_PATH "${CMAKE_SOURCE_DIR}/include")
set(SOURCE_PATH "${CMAKE_SOURCE_DIR}/src")

include_directories("${INCLUDE_PATH}")

link_libraries(lua lauxlib lualib)
link_libraries(${NOISE_LIB})

add_executable(VectorTests src/VectorTests.cc)
add_test(NAME VectorTests COMMAND VectorTests)

add_executable(BufferTests src/BufferTests.cc)
add_test(NAME BufferTests COMMAND BufferTests)