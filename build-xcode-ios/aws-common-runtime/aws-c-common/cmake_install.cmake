# Install script for directory: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common

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

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/allocator.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/array_list.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/array_list.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/assert.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/atomics.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/atomics.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/atomics_fallback.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/atomics_gnu.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/atomics_gnu_old.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/atomics_msvc.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/byte_buf.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/byte_order.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/byte_order.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/cache.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/clock.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/clock.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/command_line_parser.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/common.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/condition_variable.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/cpuid.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/date_time.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/device_random.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/encoding.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/encoding.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/environment.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/error.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/error.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/exports.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/fifo_cache.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/hash_table.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/lifo_cache.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/linked_hash_table.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/linked_list.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/linked_list.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/log_channel.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/log_formatter.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/log_writer.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/logging.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/lru_cache.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/macros.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/math.cbmc.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/math.fallback.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/math.gcc_builtin.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/math.gcc_overflow.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/math.gcc_x64_asm.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/math.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/math.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/math.msvc.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/mutex.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/package.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/platform.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/predicates.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/priority_queue.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/process.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/resource_name.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/ring_buffer.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/ring_buffer.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/rw_lock.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/statistics.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/stdbool.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/stdint.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/string.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/string.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/system_info.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/task_scheduler.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/thread.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/time.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/uuid.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/xml_parser.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/zero.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/zero.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common/posix" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/common/posix/common.inl")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/common" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-common/generated/include/aws/common/config.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/testing" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/testing/aws_test_allocators.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/aws/testing" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/include/aws/testing/aws_test_harness.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xRuntimex" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES
      "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-common.1.0.0.dylib"
      "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-common.0unstable.dylib"
      )
    foreach(file
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.1.0.0.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.0unstable.dylib"
        )
      if(EXISTS "${file}" AND
         NOT IS_SYMLINK "${file}")
        execute_process(COMMAND "/usr/bin/install_name_tool"
          -id "libaws-c-common.0unstable.dylib"
          "${file}")
      endif()
    endforeach()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES
      "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-common.1.0.0.dylib"
      "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-common.0unstable.dylib"
      )
    foreach(file
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.1.0.0.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.0unstable.dylib"
        )
      if(EXISTS "${file}" AND
         NOT IS_SYMLINK "${file}")
        execute_process(COMMAND "/usr/bin/install_name_tool"
          -id "libaws-c-common.0unstable.dylib"
          "${file}")
      endif()
    endforeach()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES
      "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-common.1.0.0.dylib"
      "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-common.0unstable.dylib"
      )
    foreach(file
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.1.0.0.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.0unstable.dylib"
        )
      if(EXISTS "${file}" AND
         NOT IS_SYMLINK "${file}")
        execute_process(COMMAND "/usr/bin/install_name_tool"
          -id "libaws-c-common.0unstable.dylib"
          "${file}")
      endif()
    endforeach()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES
      "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-common.1.0.0.dylib"
      "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-common.0unstable.dylib"
      )
    foreach(file
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.1.0.0.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.0unstable.dylib"
        )
      if(EXISTS "${file}" AND
         NOT IS_SYMLINK "${file}")
        execute_process(COMMAND "/usr/bin/install_name_tool"
          -id "libaws-c-common.0unstable.dylib"
          "${file}")
      endif()
    endforeach()
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-common.dylib")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.dylib" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.dylib")
      execute_process(COMMAND "/usr/bin/install_name_tool"
        -id "libaws-c-common.0unstable.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.dylib")
    endif()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-common.dylib")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.dylib" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.dylib")
      execute_process(COMMAND "/usr/bin/install_name_tool"
        -id "libaws-c-common.0unstable.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.dylib")
    endif()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-common.dylib")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.dylib" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.dylib")
      execute_process(COMMAND "/usr/bin/install_name_tool"
        -id "libaws-c-common.0unstable.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.dylib")
    endif()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-common.dylib")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.dylib" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.dylib")
      execute_process(COMMAND "/usr/bin/install_name_tool"
        -id "libaws-c-common.0unstable.dylib"
        "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libaws-c-common.dylib")
    endif()
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/aws-c-common/cmake/shared/aws-c-common-targets.cmake")
    file(DIFFERENT EXPORT_FILE_CHANGED FILES
         "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/aws-c-common/cmake/shared/aws-c-common-targets.cmake"
         "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-common/CMakeFiles/Export/lib/aws-c-common/cmake/shared/aws-c-common-targets.cmake")
    if(EXPORT_FILE_CHANGED)
      file(GLOB OLD_CONFIG_FILES "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/aws-c-common/cmake/shared/aws-c-common-targets-*.cmake")
      if(OLD_CONFIG_FILES)
        message(STATUS "Old export file \"$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/aws-c-common/cmake/shared/aws-c-common-targets.cmake\" will be replaced.  Removing files [${OLD_CONFIG_FILES}].")
        file(REMOVE ${OLD_CONFIG_FILES})
      endif()
    endif()
  endif()
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/aws-c-common/cmake/shared" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-common/CMakeFiles/Export/lib/aws-c-common/cmake/shared/aws-c-common-targets.cmake")
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/aws-c-common/cmake/shared" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-common/CMakeFiles/Export/lib/aws-c-common/cmake/shared/aws-c-common-targets-debug.cmake")
  endif()
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/aws-c-common/cmake/shared" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-common/CMakeFiles/Export/lib/aws-c-common/cmake/shared/aws-c-common-targets-minsizerel.cmake")
  endif()
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/aws-c-common/cmake/shared" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-common/CMakeFiles/Export/lib/aws-c-common/cmake/shared/aws-c-common-targets-relwithdebinfo.cmake")
  endif()
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/aws-c-common/cmake/shared" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-common/CMakeFiles/Export/lib/aws-c-common/cmake/shared/aws-c-common-targets-release.cmake")
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/aws-c-common/cmake" TYPE FILE FILES "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-common/aws-c-common-config.cmake")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xDevelopmentx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake" TYPE FILE FILES
    "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/cmake/AwsCFlags.cmake"
    "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/cmake/AwsCheckHeaders.cmake"
    "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/cmake/AwsSharedLibSetup.cmake"
    "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/cmake/AwsTestHarness.cmake"
    "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/cmake/AwsLibFuzzer.cmake"
    "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/cmake/AwsSanitizers.cmake"
    "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/cmake/AwsSIMD.cmake"
    "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/cmake/AwsFindPackage.cmake"
    "/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/aws-common-runtime/aws-c-common/cmake/AwsFeatureTests.cmake"
    )
endif()

