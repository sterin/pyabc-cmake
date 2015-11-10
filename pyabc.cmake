list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})

find_package(Readline)
include(install_rules)

if(EXISTS .hgsubstate)
    install(FILES .hgsubstate DESTINATION "")
endif()

configure_file(${CMAKE_CURRENT_LIST_DIR}/cpack_project_file.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/cpack_project_file.cmake @ONLY)
set(CPACK_PROJECT_CONFIG_FILE ${CMAKE_CURRENT_BINARY_DIR}/cpack_project_file.cmake)

set(CPACK_GENERATOR "TGZ")
include(CPack)
