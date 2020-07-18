cmake_minimum_required(VERSION 3.14.20190522)
project(AwsCommonRuntimeKit LANGUAGES Swift C)
option(BUILD_DEPS "Builds aws common runtime dependencies as part of build, only do this if you don't want to control your dependency chain." ON)

# place all modules into swift in the root of the build tree
set(CMAKE_Swift_MODULE_DIRECTORY "${CMAKE_BINARY_DIR}/swift")
set(CMAKE_Swift_LANGUAGE_VERSION 5)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# enable shared libraries by default (Windows, Darwin)
# Windows does not yet support static libraries in Swift, Darwin no longer
# supports static libraries after ABI stability.

include(CTest)

if (DEFINED CMAKE_PREFIX_PATH)
    file(TO_CMAKE_PATH "${CMAKE_PREFIX_PATH}" CMAKE_PREFIX_PATH)
endif()

if (DEFINED CMAKE_INSTALL_PREFIX)
    file(TO_CMAKE_PATH "${CMAKE_INSTALL_PREFIX}" CMAKE_INSTALL_PREFIX)
endif()

if (UNIX AND NOT APPLE)
    include(GNUInstallDirs)
elseif(NOT DEFINED CMAKE_INSTALL_LIBDIR)
    set(CMAKE_INSTALL_LIBDIR "lib")
endif()

if (${CMAKE_INSTALL_LIBDIR} STREQUAL "lib64")
    set(FIND_LIBRARY_USE_LIB64_PATHS true)
endif()

if (NOT CMAKE_BUILD_TYPE)
    # setting this breaks C++ builds in visualc++, so don't do it.
    if (NOT WIN32)
        set(CMAKE_BUILD_TYPE "RelWithDebInfo")
    endif()
endif()

set(AWS_CRT_SWIFT_VERSION "v0.0.1")

# This is required in order to append /lib/cmake to each element in CMAKE_PREFIX_PATH
set(AWS_MODULE_DIR "/${CMAKE_INSTALL_LIBDIR}/cmake")
string(REPLACE ";" "${AWS_MODULE_DIR};" AWS_MODULE_PATH "${CMAKE_PREFIX_PATH}${AWS_MODULE_DIR}")
# Append that generated list to the module search path
list(APPEND CMAKE_MODULE_PATH ${AWS_MODULE_PATH})

if (BUILD_DEPS)
    list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/aws-common-runtime/aws-c-common/cmake")

    set(BUILD_SHARED_LIBS OFF)
    include(AwsFindPackage)

    set(IN_SOURCE_BUILD ON)
    set(BUILD_TESTING_PREV ${BUILD_TESTING})
    set(BUILD_TESTING OFF)
    add_subdirectory(aws-common-runtime/aws-c-common)

    if (UNIX AND NOT APPLE)
        add_subdirectory(aws-common-runtime/s2n)
    endif()

    add_subdirectory(aws-common-runtime/aws-c-io)
    add_subdirectory(aws-common-runtime/aws-c-cal)
    add_subdirectory(aws-common-runtime/aws-c-compression)
    add_subdirectory(aws-common-runtime/aws-c-http)
    add_subdirectory(aws-common-runtime/aws-c-auth)
    add_subdirectory(aws-common-runtime/aws-c-mqtt)
    set(BUILD_TESTING ${BUILD_TESTING_PREV})
    set(BUILD_SHARED_LIBS ON)
else()
    include(AwsFindPackage)
    set(IN_SOURCE_BUILD OFF)
    set(BUILD_SHARED_LIBS ON)
endif()

include(AwsCFlags)
include(AwsSharedLibSetup)

foreach(C_MODULE aws-c-auth aws-c-cal aws-c-common aws-c-compression aws-c-http aws-c-io aws-c-mqtt)
    aws_use_package(${C_MODULE})

    configure_file(aws-common-runtime/${C_MODULE}.modulemap
        ${CMAKE_BINARY_DIR}/aws-common-runtime/${C_MODULE}/include/module.modulemap
        COPYONLY)

    # Copy the headers to the build directory (they need to be in the same directory than module.modulemap)
    file(GLOB_RECURSE HEADERS RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}/"
        "aws-common-runtime/${C_MODULE}/include/*.h"
        "aws-common-runtime/${C_MODULE}/include/*.inl"
        )
    foreach(HEADER ${HEADERS})
        configure_file(${HEADER} ${CMAKE_BINARY_DIR}/${HEADER} COPYONLY)
    endforeach()

    list(APPEND DEP_AWS_HEADERS ${CMAKE_BINARY_DIR}/aws-common-runtime/${C_MODULE}/include)

    # Make the new output directory the INTERFACE include path
    target_include_directories(${C_MODULE} INTERFACE
        "$<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/aws-common-runtime/${C_MODULE}/include>")
endforeach()

if (BUILD_SHARED_LIBS)
    set (TARGET_DIR "shared")
else()
    set (TARGET_DIR "static")
endif()

add_subdirectory(Source)

if (NOT CMAKE_CROSSCOMPILING)
    if (BUILD_TESTING)
        add_subdirectory(Test)
    endif()
endif()
