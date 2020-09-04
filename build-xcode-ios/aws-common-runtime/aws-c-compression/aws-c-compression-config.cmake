include(CMakeFindDependencyMacro)

find_dependency(aws-c-common)

if (BUILD_SHARED_LIBS)
    include(${CMAKE_CURRENT_LIST_DIR}/shared/aws-c-compression-targets.cmake)
else()
    include(${CMAKE_CURRENT_LIST_DIR}/static/aws-c-compression-targets.cmake)
endif()

