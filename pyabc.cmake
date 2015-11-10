list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})

find_package(Readline)
find_package(Hg REQUIRED)

include(install_rules)

if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/.hgsubstate)
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/.hgsubstate DESTINATION ".")
endif()

set(CPACK_PROJECT_CONFIG_FILE ${CMAKE_CURRENT_BINARY_DIR}/cpack_project_file.cmake)

set(CPACK_GENERATOR "TGZ")
include(CPack)

configure_file(${CMAKE_CURRENT_LIST_DIR}/cpack_project_file.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/cpack_project_file.cmake @ONLY)
