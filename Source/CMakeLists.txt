configure_file(${PROJECT_NAME}/${PROJECT_NAME}.swift.in
  ${CMAKE_CURRENT_LIST_DIR}/${PROJECT_NAME}/${PROJECT_NAME}.swift @ONLY)

file(GLOB_RECURSE AWS_CRT_SOURCES
  "AwsCommonRuntimeKit/crt/*.swift"
  "AwsCommonRuntimeKit/http/*.swift"
  "AwsCommonRuntimeKit/io/*.swift"
  "AwsCommonRuntimeKit/auth/credentials/*.swift"
  "AwsCommonRuntimeKit/auth/signing/*.swift"
  "AwsCommonRuntimeKit/mqtt/*.swift"
  "AwsCommonRuntimeKit/*.swift"
)


add_library(${PROJECT_NAME} ${AWS_CRT_SOURCES} AwsCommonRuntimeKit/crt/AWSDate.swift)


target_compile_options(${PROJECT_NAME} PRIVATE
  $<$<BOOL:BUILD_TESTING>:-enable-testing>)

target_link_libraries(${PROJECT_NAME} PUBLIC ${DEP_AWS_LIBS})
set_target_properties(${PROJECT_NAME} PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

set_target_properties(${PROJECT_NAME} PROPERTIES
        FRAMEWORK TRUE      # in my experience, this property should be TRUE
        VERSION "1.0.0"
        SOVERSION "1.0.0"
        FRAMEWORK_VERSION "A"
        )

install(TARGETS ${PROJECT_NAME}
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
  FRAMEWORK DESTINATION lib
  COMPONENT lib)


## ElastiCurl

add_executable(ElastiCurl "Elasticurl/main.swift")

target_link_libraries(ElastiCurl PUBLIC ${PROJECT_NAME})
install(TARGETS ElastiCurl
        RUNTIME DESTINATION bin
        )
