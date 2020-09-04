# TODO: be more dynamic with setting this
if(NOT DEFINED CMAKE_OSX_SYSROOT)
    execute_process(COMMAND xcodebuild -version -sdk iphoneos Path
        OUTPUT_VARIABLE CMAKE_OSX_SYSROOT
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()

# need these in the toolchain file otherwise AWS ignores them when passed in directly
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO")
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "")
