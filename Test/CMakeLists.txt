enable_testing()
find_package(XCTest REQUIRED)

file(GLOB TEST_SRC
        "AwsCommonRuntimeKitTests/http/*.swift"
        "AwsCommonRuntimeKitTests/crt/*.swift"
        "AwsCommonRuntimeKitTests/io/*.swift"
        "AwsCommonRuntimeKitTests/auth/*.swift"
        "AwsCommonRuntimeKitTests/CrtXCBaseTestCase.swift"
  )

xctest_add_bundle(AwsCommonRuntimeKitTests AwsCommonRuntimeKit ${TEST_SRC})

xctest_add_test(XCTest.AwsCommonRuntimeKit AwsCommonRuntimeKitTests)
