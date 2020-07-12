enable_testing()
find_package(XCTest REQUIRED)

file(GLOB_RECURSE TEST_SRC
        "AwsCommonRuntimeKitTests/http/*.swift"
  )

xctest_add_bundle(AwsCommonRuntimeKitTests AwsCommonRuntimeKit ${TEST_SRC})

xctest_add_test(XCTest.AwsCommonRuntimeKit AwsCommonRuntimeKitTests)