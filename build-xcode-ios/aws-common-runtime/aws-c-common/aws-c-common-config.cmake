set(THREADS_PREFER_PTHREAD_FLAG ON)

if(WIN32 OR UNIX OR APPLE)
    find_package(Threads REQUIRED)
endif()

if (BUILD_SHARED_LIBS)
    include(${CMAKE_CURRENT_LIST_DIR}/shared/aws-c-common-targets.cmake)
else()
    include(${CMAKE_CURRENT_LIST_DIR}/static/aws-c-common-targets.cmake)
endif()

