#----------------------------------------------------------------
# Generated CMake target import file for configuration "Debug".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "AWS::aws-c-compression" for configuration "Debug"
set_property(TARGET AWS::aws-c-compression APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(AWS::aws-c-compression PROPERTIES
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/lib/libaws-c-compression.1.0.0.dylib"
  IMPORTED_SONAME_DEBUG "libaws-c-compression.0unstable.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS AWS::aws-c-compression )
list(APPEND _IMPORT_CHECK_FILES_FOR_AWS::aws-c-compression "${_IMPORT_PREFIX}/lib/libaws-c-compression.1.0.0.dylib" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
