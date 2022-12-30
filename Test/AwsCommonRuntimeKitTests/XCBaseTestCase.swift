//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import AwsCommonRuntimeKit
import AwsCCommon

class XCBaseTestCase: XCTestCase {
    internal let allocator = TracingAllocator(tracingStacksOf: defaultAllocator)
    let logging = Logger(pipe: stdout, level: .trace, allocator: defaultAllocator)

    override func setUp() {
        super.setUp()

        CommonRuntimeKit.initialize(allocator: self.allocator)
    }

    override func tearDown() {
        CommonRuntimeKit.cleanUp()

        allocator.dump()
        XCTAssertEqual(allocator.count, 0,
                       "Memory was leaked: \(allocator.bytes) bytes in \(allocator.count) allocations")

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
