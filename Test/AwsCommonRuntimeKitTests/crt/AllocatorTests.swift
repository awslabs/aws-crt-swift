//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AwsCommonRuntimeKit
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest

class TracingAllocatorTests: CrtXCBaseTestCase {
    func testTracingAllocatorCorrectlyTracesAllocations() throws {
        let allocator = TracingAllocator(tracingBytesOf: defaultAllocator)
        XCTAssertEqual(allocator.bytes, 0)
        XCTAssertEqual(allocator.count, 0)

        let ptr1: UnsafeMutablePointer<UInt32> = try allocator.allocate(capacity: 5)
        XCTAssertEqual(allocator.bytes, 20)
        XCTAssertEqual(allocator.count, 1)

        let ptr2: UnsafeMutablePointer<UInt8> = try allocator.allocate(capacity: 1_024)
        XCTAssertEqual(allocator.bytes, 1_044)
        XCTAssertEqual(allocator.count, 2)

        allocator.release(ptr1)
        XCTAssertEqual(allocator.bytes, 1_024)
        XCTAssertEqual(allocator.count, 1)

        allocator.release(ptr2)
        XCTAssertEqual(allocator.bytes, 0)
        XCTAssertEqual(allocator.count, 0)
    }
}
