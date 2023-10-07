macro(subdir_list result current_dir)
  # get ALL immediate children of this directory
  file(GLOB children RELATIVE ${current_dir} ${current_dir}/*)

  set(dir_list "")
  foreach(child ${children})
    if(IS_DIRECTORY ${current_dir}/${child})
      LIST(APPEND dir_list ${child})
    endif()
  endforeach()

  set(${result} ${dir_list})
endmacro()
