# Install script for directory: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/Source

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

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xlibx" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE DIRECTORY FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/AwsCommonRuntimeKit.framework" USE_SOURCE_PERMISSIONS)
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/AwsCommonRuntimeKit.framework/AwsCommonRuntimeKit" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/AwsCommonRuntimeKit.framework/AwsCommonRuntimeKit")
      execute_process(COMMAND "/usr/bin/install_name_tool"
        -id "AwsCommonRuntimeKit.framework/AwsCommonRuntimeKit"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-auth.0unstable.dylib" "libaws-c-auth.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-cal.0unstable.dylib" "libaws-c-cal.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-common.0unstable.dylib" "libaws-c-common.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-compression.0unstable.dylib" "libaws-c-compression.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-http.0unstable.dylib" "libaws-c-http.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-io.0unstable.dylib" "libaws-c-io.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-mqtt.0unstable.dylib" "libaws-c-mqtt.0unstable.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/AwsCommonRuntimeKit.framework/AwsCommonRuntimeKit")
    endif()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE DIRECTORY FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/AwsCommonRuntimeKit.framework" USE_SOURCE_PERMISSIONS)
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/AwsCommonRuntimeKit.framework/AwsCommonRuntimeKit" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/AwsCommonRuntimeKit.framework/AwsCommonRuntimeKit")
      execute_process(COMMAND "/usr/bin/install_name_tool"
        -id "AwsCommonRuntimeKit.framework/AwsCommonRuntimeKit"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-auth.0unstable.dylib" "libaws-c-auth.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-cal.0unstable.dylib" "libaws-c-cal.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-common.0unstable.dylib" "libaws-c-common.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-compression.0unstable.dylib" "libaws-c-compression.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-http.0unstable.dylib" "libaws-c-http.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-io.0unstable.dylib" "libaws-c-io.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-mqtt.0unstable.dylib" "libaws-c-mqtt.0unstable.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/AwsCommonRuntimeKit.framework/AwsCommonRuntimeKit")
    endif()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE DIRECTORY FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/AwsCommonRuntimeKit.framework" USE_SOURCE_PERMISSIONS)
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/AwsCommonRuntimeKit.framework/AwsCommonRuntimeKit" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/AwsCommonRuntimeKit.framework/AwsCommonRuntimeKit")
      execute_process(COMMAND "/usr/bin/install_name_tool"
        -id "AwsCommonRuntimeKit.framework/AwsCommonRuntimeKit"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-auth.0unstable.dylib" "libaws-c-auth.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-cal.0unstable.dylib" "libaws-c-cal.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-common.0unstable.dylib" "libaws-c-common.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-compression.0unstable.dylib" "libaws-c-compression.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-http.0unstable.dylib" "libaws-c-http.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-io.0unstable.dylib" "libaws-c-io.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-mqtt.0unstable.dylib" "libaws-c-mqtt.0unstable.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/AwsCommonRuntimeKit.framework/AwsCommonRuntimeKit")
    endif()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE DIRECTORY FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/AwsCommonRuntimeKit.framework" USE_SOURCE_PERMISSIONS)
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/AwsCommonRuntimeKit.framework/AwsCommonRuntimeKit" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/AwsCommonRuntimeKit.framework/AwsCommonRuntimeKit")
      execute_process(COMMAND "/usr/bin/install_name_tool"
        -id "AwsCommonRuntimeKit.framework/AwsCommonRuntimeKit"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-auth.0unstable.dylib" "libaws-c-auth.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-cal.0unstable.dylib" "libaws-c-cal.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-common.0unstable.dylib" "libaws-c-common.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-compression.0unstable.dylib" "libaws-c-compression.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-http.0unstable.dylib" "libaws-c-http.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-io.0unstable.dylib" "libaws-c-io.0unstable.dylib"
        -change "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-mqtt.0unstable.dylib" "libaws-c-mqtt.0unstable.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/AwsCommonRuntimeKit.framework/AwsCommonRuntimeKit")
    endif()
  endif()
endif()

