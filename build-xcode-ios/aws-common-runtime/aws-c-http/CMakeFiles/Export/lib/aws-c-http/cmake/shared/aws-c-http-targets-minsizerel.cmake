#----------------------------------------------------------------
# Generated CMake target import file for configuration "MinSizeRel".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "AWS::aws-c-http" for configuration "MinSizeRel"
set_property(TARGET AWS::aws-c-http APPEND PROPERTY IMPORTED_CONFIGURATIONS MINSIZEREL)
set_target_properties(AWS::aws-c-http PROPERTIES
  IMPORTED_LOCATION_MINSIZEREL "${_IMPORT_PREFIX}/lib/libaws-c-http.1.0.0.dylib"
  IMPORTED_SONAME_MINSIZEREL "libaws-c-http.0unstable.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS AWS::aws-c-http )
list(APPEND _IMPORT_CHECK_FILES_FOR_AWS::aws-c-http "${_IMPORT_PREFIX}/lib/libaws-c-http.1.0.0.dylib" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
