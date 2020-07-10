configure_file(${PROJECT_NAME}/${PROJECT_NAME}.swift.in
  ${CMAKE_CURRENT_LIST_DIR}/${PROJECT_NAME}/${PROJECT_NAME}.swift @ONLY)

file(GLOB_RECURSE AWS_CRT_SOURCES
  "${PROJECT_NAME}/*.swift"
)

add_library(${PROJECT_NAME} ${AWS_CRT_SOURCES} AwsCommonRuntimeKit/http/HttpHeaderBlock.swift AwsCommonRuntimeKit/http/HttpProxyAuthenticationType.swift AwsCommonRuntimeKit/http/HttpClientConnectionOptions.swift AwsCommonRuntimeKit/http/HttpClientConnectionProxyOptions.swift AwsCommonRuntimeKit/http/HttpStream.swift AwsCommonRuntimeKit/http/HttpRequestOptions.swift AwsCommonRuntimeKit/http/HttpStreamCalbackData.swift AwsCommonRuntimeKit/http/HttpClientConnectionCallbackData.swift AwsCommonRuntimeKit/http/HttpMessage.swift AwsCommonRuntimeKit/http/HttpResponse.swift AwsCommonRuntimeKit/http/HttpHeaders.swift AwsCommonRuntimeKit/http/HttpHeaderCompression.swift)

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


## ElastiCurl

add_executable(ElastiCurl "ElastiCurl.swift")
target_link_libraries(ElastiCurl PRIVATE ${PROJECT_NAME})

install(TARGETS ElastiCurl
        RUNTIME DESTINATION bin
        )