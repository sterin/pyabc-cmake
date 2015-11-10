include(CMakeParseArguments)


function(_pyabc_execute_process)

    cmake_parse_arguments(dd "" "DEFAULT;OUTPUT_VARIABLE" "" ${ARGN} )

    execute_process( ${dd_UNPARSED_ARGUMENTS} OUTPUT_VARIABLE output)
    string(STRIP "${output}" output)

    if(output STREQUAL "")
        set(${dd_OUTPUT_VARIABLE} ${dd_DEFAULT} PARENT_SCOPE)
    else()
        set(${dd_OUTPUT_VARIABLE} "${output}" PARENT_SCOPE)
    endif()

endfunction()


function(pyabc_get_system_name var)

    if(APPLE)

        _pyabc_execute_process(COMMAND sw_vers -productName OUTPUT_VARIABLE os DEFAULT unknown)
        string(REPLACE " " "_" os ${os})

        _pyabc_execute_process(COMMAND sw_vers -productVersion OUTPUT_VARIABLE version DEFAULT unknown)
        set(${var} ${os}_${version} PARENT_SCOPE)

    elseif(EXISTS /etc/os-release)

        file(READ /etc/os-release os_release)
        string(REPLACE "\n" ";" os_release ${os_release})

        foreach(line ${os_release})
            if( line MATCHES "^ID=" )
                string(REGEX REPLACE "ID=([^ ]+)" "\\1" distro ${line})
            elseif( line MATCHES "^VERSION_ID=")
                string(REGEX REPLACE "VERSION_ID=([^ ]+)" "\\1" version ${line})
                if( version MATCHES "^\".+\"$")
                    string(REGEX REPLACE "\"(.+)\"" "\\1" version ${version})
                endif()
            endif()
        endforeach()

        set(${var} ${distro}_${version} PARENT_SCOPE)

    elseif(EXISTS /etc/redhat-release)

        file(READ /etc/redhat-release redhat_release)
        string(REGEX REPLACE "^(.*) release ([^ ]+).*$" "\\1_\\2" redhat_release ${redhat_release})
        string(REPLACE " " "_" redhat_release ${redhat_release})

        set(${var} "${redhat_release}" PARENT_SCOPE)

    else()

        _pyabc_execute_process(COMMAND lsb_release -si OUTPUT_VARIABLE distro DEFAULT unknown)
        _pyabc_execute_process(COMMAND lsb_release -sr OUTPUT_VARIABLE release DEFAULT unknown)

        set(${var} ${distro}_${release} PARENT_SCOPE)

    endif()

endfunction()


function(_pyabc_run_hg src_dir var)

    execute_process(COMMAND ${ARGN} WORKING_DIRECTORY ${src_dir} OUTPUT_VARIABLE tmp)
    string(STRIP ${tmp} tmp)
    set(${var} ${tmp} PARENT_SCOPE)
    message("${var}: ${tmp}")

endfunction()


function(pyabc_get_version src_dir var)

    _pyabc_run_hg(${src_dir} latesttag hg log -r . --template "{latesttag}" )
    _pyabc_run_hg(${src_dir} status hg status -mardn --subrepos --rev="${latesttag}" )


    if( status STREQUAL ".hgtags" )
        set(${var} ${latesttag} PARENT_SCOPE)
    else()
        _pyabc_run_hg(${src_dir} latesttagdistance hg log -r . --template "{latesttagdistance}" )
        _pyabc_run_hg(${src_dir} latesttag hg log -r . --template "{latesttag}" )
        _pyabc_run_hg(${src_dir} node hg log -r . --template "{node|short}" )
        set(${var} ${latesttag}-${latesttagdistance}-${node} PARENT_SCOPE)
    endif()

endfunction()
