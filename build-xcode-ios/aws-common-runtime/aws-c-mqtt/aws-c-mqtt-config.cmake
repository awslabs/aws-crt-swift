include(CMakeFindDependencyMacro)

find_dependency(aws-c-io)

if (ON)
    find_dependency(aws-c-http)
endif()

if (BUILD_SHARED_LIBS)
    include(${CMAKE_CURRENT_LIST_DIR}/shared/aws-c-mqtt-targets.cmake)
else()
    include(${CMAKE_CURRENT_LIST_DIR}/static/aws-c-mqtt-targets.cmake)
endif()

