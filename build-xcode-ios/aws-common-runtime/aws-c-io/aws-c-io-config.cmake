include(CMakeFindDependencyMacro)

if (UNIX AND NOT APPLE)
    find_dependency(s2n)
    find_dependency(LibCrypto)
endif()

find_dependency(aws-c-common)

if (BUILD_SHARED_LIBS)
    include(${CMAKE_CURRENT_LIST_DIR}/shared/aws-c-io-targets.cmake)
else()
    include(${CMAKE_CURRENT_LIST_DIR}/static/aws-c-io-targets.cmake)
endif()

