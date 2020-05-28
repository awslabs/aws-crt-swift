configure_file(${PROJECT_NAME}/${PROJECT_NAME}.swift.in
  ${CMAKE_CURRENT_LIST_DIR}/${PROJECT_NAME}/${PROJECT_NAME}.swift @ONLY)

file(GLOB_RECURSE AWS_CRT_SOURCES
  "${PROJECT_NAME}/*.swift"
)

add_library(${PROJECT_NAME} ${AWS_CRT_SOURCES})

target_compile_options(${PROJECT_NAME} PRIVATE
  $<$<BOOL:BUILD_TESTING>:-enable-testing>)
set_target_properties(${PROJECT_NAME} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
  "${CMAKE_Swift_MODULE_DIRECTORY}"
  )

target_link_libraries(${PROJECT_NAME} PUBLIC ${DEP_AWS_LIBS})

install(TARGETS ${PROJECT_NAME}
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
  COMPONENT lib)


## ElastiCulr

add_executable(ElastiCurl "ElastiCurl.swift")
target_link_libraries(ElastiCurl PRIVATE ${PROJECT_NAME})

install(TARGETS ElastiCurl
        RUNTIME DESTINATION bin
        )