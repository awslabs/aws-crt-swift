//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit
import AwsCCommon

class XCBaseTestCase: XCTestCase {
    internal let tracingAllocator = TracingAllocator(tracingStacksOf: allocator)

    override func setUp() {
        super.setUp()
        Logger.initilize(pipe: stdout, level: .trace)

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
        if #available(iOS 10, *) {
            throw XCTSkip("Skipping test on iOS")
        }
    }

    func skipifmacOS() throws {
        if #available(macOS 10.14, *) {
            throw XCTSkip("Skipping test on macOS")
        }
    }

    func skipIfLinux() throws {
        #if os(Linux)
            throw XCTSkip("Skipping test on linux")
        #endif
    }
}
