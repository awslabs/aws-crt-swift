include(CMakeFindDependencyMacro)

find_dependency(aws-c-io)
find_dependency(aws-c-compression)

if (BUILD_SHARED_LIBS)
    include(${CMAKE_CURRENT_LIST_DIR}/shared/aws-c-http-targets.cmake)
else()
    include(${CMAKE_CURRENT_LIST_DIR}/static/aws-c-http-targets.cmake)
endif()

