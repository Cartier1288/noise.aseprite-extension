cmake_minimum_required(VERSION 3.16)

project(
  noise.aseprite-extension
  VERSION 1.0.0
  LANGUAGES C CXX
)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(INSTALL_DIR "${CMAKE_SOURCE_DIR}/bin")
set(NOISE_LIB noise)
set(NOISE_LIB_NAME noise)

#set(CONFIG_INCLUDE_PATH "${CMAKE_BINARY_DIR}/configured_files/include")
#set(CONFIG_PATH "${CONFIG_INCLUDE_PATH}/suki/config.h")

set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/")
include(AddGitSubmodule)

#add_git_submodule(external/lua)

add_subdirectory(src)

