# Install script for directory: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-compression

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/usr/local")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "TRUE")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xRuntimex" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES
      "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-compression.1.0.0.dylib"
      "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-compression.0unstable.dylib"
      )
    foreach(file
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.1.0.0.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.0unstable.dylib"
        )
      if(EXISTS "${file}" AND
         NOT IS_SYMLINK "${file}")
        execute_process(COMMAND "/usr/bin/install_name_tool"
          -id "libaws-c-compression.0unstable.dylib"
          -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-common.0unstable.dylib" "libaws-c-common.0unstable.dylib"
          "${file}")
      endif()
    endforeach()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES
      "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-compression.1.0.0.dylib"
      "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-compression.0unstable.dylib"
      )
    foreach(file
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.1.0.0.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.0unstable.dylib"
        )
      if(EXISTS "${file}" AND
         NOT IS_SYMLINK "${file}")
        execute_process(COMMAND "/usr/bin/install_name_tool"
          -id "libaws-c-compression.0unstable.dylib"
          -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-common.0unstable.dylib" "libaws-c-common.0unstable.dylib"
          "${file}")
      endif()
    endforeach()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES
      "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-compression.1.0.0.dylib"
      "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-compression.0unstable.dylib"
      )
    foreach(file
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.1.0.0.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.0unstable.dylib"
        )
      if(EXISTS "${file}" AND
         NOT IS_SYMLINK "${file}")
        execute_process(COMMAND "/usr/bin/install_name_tool"
          -id "libaws-c-compression.0unstable.dylib"
          -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-common.0unstable.dylib" "libaws-c-common.0unstable.dylib"
          "${file}")
      endif()
    endforeach()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES
      "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-compression.1.0.0.dylib"
      "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-compression.0unstable.dylib"
      )
    foreach(file
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.1.0.0.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.0unstable.dylib"
        )
      if(EXISTS "${file}" AND
         NOT IS_SYMLINK "${file}")
        execute_process(COMMAND "/usr/bin/install_name_tool"
          -id "libaws-c-compression.0unstable.dylib"
          -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-common.0unstable.dylib" "libaws-c-common.0unstable.dylib"
          "${file}")
      endif()
    endforeach()
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-compression.dylib")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.dylib" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.dylib")
      execute_process(COMMAND "/usr/bin/install_name_tool"
        -id "libaws-c-compression.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-common.0unstable.dylib" "libaws-c-common.0unstable.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.dylib")
    endif()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-compression.dylib")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.dylib" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.dylib")
      execute_process(COMMAND "/usr/bin/install_name_tool"
        -id "libaws-c-compression.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-common.0unstable.dylib" "libaws-c-common.0unstable.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.dylib")
    endif()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-compression.dylib")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.dylib" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.dylib")
      execute_process(COMMAND "/usr/bin/install_name_tool"
        -id "libaws-c-compression.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-common.0unstable.dylib" "libaws-c-common.0unstable.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.dylib")
    endif()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-compression.dylib")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.dylib" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.dylib")
      execute_process(COMMAND "/usr/bin/install_name_tool"
        -id "libaws-c-compression.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-common.0unstable.dylib" "libaws-c-common.0unstable.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-compression.dylib")
    endif()
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/compression" TYPE FILE FILES
    "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-compression/include/aws/compression/compression.h"
    "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-compression/include/aws/compression/exports.h"
    "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-compression/include/aws/compression/huffman.h"
    )
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/testing/compression" TYPE FILE FILES
    "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-compression/include/aws/testing/compression/huffman.h"
    "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-compression/include/aws/testing/compression/huffman.inl"
    )
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/aws-c-compression/cmake/shared/aws-c-compression-targets.cmake")
    file(DIFFERENT EXPORT_FILE_CHANGED FILES
         "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/aws-c-compression/cmake/shared/aws-c-compression-targets.cmake"
         "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-compression/CMakeFiles/Export/lib/aws-c-compression/cmake/shared/aws-c-compression-targets.cmake")
    if(EXPORT_FILE_CHANGED)
      file(GLOB OLD_CONFIG_FILES "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/aws-c-compression/cmake/shared/aws-c-compression-targets-*.cmake")
      if(OLD_CONFIG_FILES)
        message(STATUS "Old export file \"$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/aws-c-compression/cmake/shared/aws-c-compression-targets.cmake\" will be replaced.  Removing files [${OLD_CONFIG_FILES}].")
        file(REMOVE ${OLD_CONFIG_FILES})
      endif()
    endif()
  endif()
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/aws-c-compression/cmake/shared" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-compression/CMakeFiles/Export/lib/aws-c-compression/cmake/shared/aws-c-compression-targets.cmake")
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/aws-c-compression/cmake/shared" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-compression/CMakeFiles/Export/lib/aws-c-compression/cmake/shared/aws-c-compression-targets-debug.cmake")
  endif()
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/aws-c-compression/cmake/shared" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-compression/CMakeFiles/Export/lib/aws-c-compression/cmake/shared/aws-c-compression-targets-minsizerel.cmake")
  endif()
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/aws-c-compression/cmake/shared" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-compression/CMakeFiles/Export/lib/aws-c-compression/cmake/shared/aws-c-compression-targets-relwithdebinfo.cmake")
  endif()
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/aws-c-compression/cmake/shared" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-compression/CMakeFiles/Export/lib/aws-c-compression/cmake/shared/aws-c-compression-targets-release.cmake")
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/aws-c-compression/cmake" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-compression/aws-c-compression-config.cmake")
endif()

