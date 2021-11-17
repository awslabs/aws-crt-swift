//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import AwsCommonRuntimeKit
import AwsCCommon

class CrtXCBaseTestCase: XCTestCase {
    internal let allocator = TracingAllocator(tracingStacksOf: defaultAllocator)
    let logging = Logger(pipe: stdout, level: .trace, allocator: defaultAllocator)

    override func setUp() {
        super.setUp()

        AwsCommonRuntimeKit.initialize(allocator: self.allocator)
    }

//    override func tearDown() {
//        AwsCommonRuntimeKit.cleanUp()
//
//        allocator.dump()
//        XCTAssertEqual(allocator.count, 0,
//                       "Memory was leaked: \(allocator.bytes) bytes in \(allocator.count) allocations")
//
//        super.tearDown()
//    }
    
    override func tearDown() async throws {
        AwsCommonRuntimeKit.cleanUp()

        allocator.dump()
        XCTAssertEqual(allocator.count, 0,
                       "Memory was leaked: \(allocator.bytes) bytes in \(allocator.count) allocations")

        try await super.tearDown()
    }
    
//    public func XCTRunAsyncAndBlock(_ closure: @escaping () async throws -> Void) {
//        let dg = DispatchGroup()
//        dg.enter()
//        Task {
//            do {
//                try await closure()
//            } catch {
//                XCTFail("\(error)")
//            }
//            dg.leave()
//        }
//        dg.wait()
//    }
    
    public func XCTRunAsyncAndBlock(_ closure: () async throws -> Void) async throws {

        try await closure()
    }
}


extension XCTestCase {
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
