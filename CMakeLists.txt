cmake_minimum_required(VERSION 3.16)

project(
  noise.aseprite-extension
  VERSION 0.1.0
  LANGUAGES C CXX
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_SHARED_LIBRARY_PREFIX "lib")

set(INSTALL_DIR "${CMAKE_SOURCE_DIR}/bin")
set(NOISE_LIB noise)
set(NOISE_LIB_NAME noise)

#set(CONFIG_INCLUDE_PATH "${CMAKE_BINARY_DIR}/configured_files/include")
#set(CONFIG_PATH "${CONFIG_INCLUDE_PATH}/suki/config.h")

set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/")
include(AddGitSubmodule)

#add_git_submodule(external/lua)

message("configuring noise plugin for ${CMAKE_CXX_COMPILER_ID}")
if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
  # force MSVC to conform to standard preprocessor, otherwise recursive macro used in worley for
  # generic test cases breaks.
  add_compile_options(/Zc:preprocessor)
  # because stdc++17 for MSVC cannot handle the following fold expression in template declaration:
  #  template<typename TT=T, typename... Args,
  #      std::enable_if_t<
  #          std::is_constructible<T, TT>::value &&
  #          (std::is_constructible<T, Args>::value && ...) &&
  #          !std::is_same<std::decay_t<TT>, vec>::value,
  #          int
  #      > = false
  #  >
  add_compile_options(/std:c++latest)
endif()

add_subdirectory(external)
add_subdirectory(src)

if(NOT EXCLUDE_TESTS)
  enable_testing()
  add_subdirectory(tests)
endif()

