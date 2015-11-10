include(CheckLibraryExists)
include(CMakeParseArguments)
include(FindPackageHandleStandardArgs)

function(_pyabc_check_library_links)

    cmake_parse_arguments(cll "" "FUNCTION;RESULT_VARIABLE" "LIBRARIES;FLAGS" ${ARGN})

    list(GET cll_LIBRARIES 0 first_lib)
    list(REMOVE_AT cll_LIBRARIES 0)

    set(CMAKE_REQUIRED_FLAGS ${cll_FLAGS})
    set(CMAKE_REQUIRED_LIBRARIES ${cll_LIBRARIES})

    check_library_exists(${first_lib} "${cll_FUNCTION}" "" ${cll_RESULT_VARIABLE})
    set(${cll_RESULT_VARIABLE} ${${cll_RESULT_VARIABLE}} PARENT_SCOPE)

endfunction()

find_path(READLINE_INCLUDE_1 NAMES readline/readline.h)
find_library(READLINE_LIBRARIES_1 NAMES readline)

# some linux distribution require linking with curses

find_package(Curses)

if(CURSES_FOUND)
    set(READLINE_curses_LIBRARIES ${CURSES_LIBRARIES})
else()
    find_library(READLINE_curses_LIBRARIES_1 NAMES ncurses)
    if(READLINE_curses_LIBRARIES_1)
        set(READLINE_curses_LIBRARIES ${READLINE_curses_LIBRARIES_1})
    endif()
endif()

# check if linking with readline actually works, if not try add curses

if(READLINE_INCLUDE_1 AND READLINE_LIBRARIES_1)

    _pyabc_check_library_links(FUNCTION readline LIBRARIES ${READLINE_LIBRARIES_1} RESULT_VARIABLE READLINE_links_alone)

    if(READLINE_links_alone)
        set(READLINE_INCLUDE ${READLINE_INCLUDE_1})
        set(READLINE_LIBRARIES ${READLINE_LIBRARIES_1})
    else()

        _pyabc_check_library_links(FUNCTION readline LIBRARIES ${READLINE_LIBRARIES_1} ${READLINE_curses_LIBRARIES} RESULT_VARIABLE READLINE_links_with_curses)

        if(READLINE_links_with_curses)
            set(READLINE_INCLUDE ${READLINE_INCLUDE_1})
            set(READLINE_LIBRARIES ${READLINE_LIBRARIES_1} ${READLINE_curses_LIBRARIES})
        endif()

    endif()

endif()

find_package_handle_standard_args(Readline FOUND_VAR READLINE_FOUND REQUIRED_VARS READLINE_INCLUDE READLINE_LIBRARIES)
