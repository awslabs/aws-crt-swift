//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit
import AwsCCommon

class XCBaseTestCase: XCTestCase {
    internal let tracingAllocator = TracingAllocator(tracingStacksOf: allocator)

    override func setUp() {
        super.setUp()
        // XCode currently lacks a way to enable logs exclusively for failed tests only.
        // To prevent log spamming, we use `error` log level to only print error message.
        // We should update this once a more efficient log processing method becomes available.
        try! Logger.initialize(target: .standardOutput, level: .error)

        // Override the allocator with tracing allocator
        allocator = tracingAllocator.rawValue
        CommonRuntimeKit.initialize()
    }

    override func tearDown() {
        CommonRuntimeKit.cleanUp()

        tracingAllocator.dump()
        XCTAssertEqual(tracingAllocator.count, 0,
                       "Memory was leaked: \(tracingAllocator.bytes) bytes in \(tracingAllocator.count) allocations")

        super.tearDown()
    }
}


extension XCTestCase {
    func skipTest(message: String) throws {
       throw XCTSkip(message)
    }

    func skipIfiOS() throws {
        #if os(iOS)
            throw XCTSkip("Skipping test on iOS")
        #endif
    }

    func skipifmacOS() throws {
        #if os(macOS)
            throw XCTSkip("Skipping test on macOS")
        #endif
    }

    func skipIfLinux() throws {
        #if os(Linux)
            throw XCTSkip("Skipping test on linux")
        #endif
    }

    func skipIfwatchOS() throws {
        #if os(watchOS)
            throw XCTSkip("Skipping test on watchOS")
        #endif
    }

    func skipIftvOS() throws {
        #if os(tvOS)
            throw XCTSkip("Skipping test on tvOS")
        #endif
    }

    /// Return the environment variable value, or Skip the test if env var is not set.
    func getEnvironmentVarOrSkipTest(environmentVarName name: String) throws -> String {
        guard let result = ProcessInfo.processInfo.environment[name] else {
            throw XCTSkip("Skipping test because environment is not configured properly.")
        }
        return result
    }
}
