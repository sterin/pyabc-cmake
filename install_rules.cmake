# seed the random number generator, for consistency between runs
string(RANDOM RANDOM_SEED 0 "__dummy_random__")

include(CMakeParseArguments)

find_package(PythonInterp 2.7 REQUIRED)
find_package(Hg REQUIRED)


# execute a process during the instllaiton stage
function(_pyabc_install_execute_process)

    cmake_parse_arguments(zz "" "WORKING_DIRECTORY" "COMMAND" ${ARGN})

    set(cmd "")

    foreach(c ${zz_COMMAND})
        string(CONCAT cmd ${cmd} "\"${c}\" " )
    endforeach()

    if( zz_WORKING_DIRECTORY )
        string(CONCAT cmd ${cmd} "WORKING_DIRECTORY ${zz_WORKING_DIRECTORY}")
    endif()

    install(CODE "execute_process( COMMAND echo EXECUTING COMMAND: ${cmd} )")
    install(CODE "execute_process( COMMAND ${cmd} )")

endfunction()


# make a directory during the installation stage
function(_pyabc_install_mkdir dest dest_dir)
    set(dir "\${CMAKE_INSTALL_PREFIX}/${dest}")
    set(${dest_dir} ${dir} PARENT_SCOPE)
    _pyabc_install_execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${dir})

endfunction()


function(install_python_module path)
    get_filename_component(module ${path} NAME)
    install(DIRECTORY ${path} DESTINATION lib FILES_MATCHING PATTERN "*.py")
    _pyabc_install_execute_process(COMMAND ${PYTHON_EXECUTABLE} -m compileall -q \${CMAKE_INSTALL_PREFIX}/lib/${module}/)
endfunction()


# ugly hack: cmake's install(TARGETS ...) only works on targets in the current directory. We create a custom target
# that depends on all the targets specified by install_target, and make it a prerequisite of ALL
add_custom_target(pyabc_installed_targets ALL)

# and another target for tasks to be execute before install (write the locations of the targets into files, writing a version file, etc.)
add_custom_target(pyabc_all_targets_for_install)
_pyabc_install_execute_process(COMMAND ${CMAKE_COMMAND} --build ${CMAKE_CURRENT_BINARY_DIR} --target pyabc_all_targets_for_install)

# another ugly hack: the location of the target is not know when cmake is run
# to workaround that, we add a new custom target whose command writes the target
# location to file, which is read during installation

function(_pyabc_target_location target location_target location_file)
    string(MAKE_C_IDENTIFIER pyabc_installed_targets--${target} tmp)
    set(${location_target} ${tmp} PARENT_SCOPE)
    set(${location_file} ${CMAKE_CURRENT_BINARY_DIR}/${tmp}.txt PARENT_SCOPE)
endfunction()

# save repository version
_pyabc_install_execute_process(
    COMMAND
        bash -c "${HG_EXECUTABLE} log -r . --template {latesttag}-{latesttagdistance}-{node} \> \${CMAKE_INSTALL_PREFIX}/VERSION.txt"
    WORKING_DIRECTORY
        ${CMAKE_CURRENT_SOURCE_DIR}
)


function(install_target target)

    cmake_parse_arguments(zz "" "DESTINATION;RENAME" "" ${ARGN})

    set(dest ${zz_DESTINATION})

    add_dependencies(pyabc_installed_targets ${target})

    _pyabc_target_location(${target} location_target location_file)

    add_custom_target(
        ${location_target}
        echo $<TARGET_FILE:${target}> \> ${location_file}
        BYPRODUCTS ${location_file}
    )

    add_dependencies(pyabc_all_targets_for_install ${location_target})

    _pyabc_install_mkdir(${dest} dest_dir)

    if(zz_RENAME)
        set(dest_dir "${dest_dir}/${zz_RENAME}")
    endif()

    _pyabc_install_execute_process(COMMAND bash -c "cp $(< ${location_file}) ${dest_dir}")

endfunction()


function(_pyabc_install_python_library dest)

    execute_process(
        COMMAND
            ${PYTHON_EXECUTABLE} -c "import sys; sys.stdout.write('%s/lib/python%s/'%(sys.prefix,sys.version[:3]))"
        OUTPUT_VARIABLE
            lib_dir
    )

    _pyabc_install_mkdir(${dest} dest_dir)
    _pyabc_install_execute_process(COMMAND zip -q -R ${dest_dir}/python_library.zip "*.pyc" WORKING_DIRECTORY ${lib_dir})

    install(FILES ${lib_dir}/LICENSE.txt DESTINATION lib RENAME Python_LICENSE.txt )

    execute_process(
        COMMAND
            ${PYTHON_EXECUTABLE} -c "import sys; sys.stdout.write('%s/lib/python%s/lib-dynload'%(sys.exec_prefix,sys.version[:3]))"
        OUTPUT_VARIABLE
            dylib_dir
    )

    _pyabc_install_execute_process(COMMAND bash -c "cp -rf * ${dest_dir}" WORKING_DIRECTORY ${dylib_dir} )

endfunction()


function(pyabc_install_support_libraries)

    if(PYABC_INSTALL_SUPPORT_LIBRARIES)

        _pyabc_install_python_library(lib)

        foreach(exe ${ARGN})
            get_target_property(link_flags ${exe} LINK_FLAGS)
            if(link_flags)
                message("set_target_properties(${exe} PROPERTIES LINK_FLAGS \"${link_flags} -static-libgcc -static-libstdc++\")")
                set_target_properties(${exe} PROPERTIES LINK_FLAGS "${link_flags} -static-libgcc -static-libstdc++")
            else()
                message("set_target_properties(${exe} PROPERTIES LINK_FLAGS \"-static-libgcc -static-libstdc++\")")
                set_target_properties(${exe} PROPERTIES LINK_FLAGS "-static-libgcc -static-libstdc++")
            endif()
        endforeach()

    endif()

endfunction()
