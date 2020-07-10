//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

@testable
import AwsCommonRuntimeKit
import Foundation

class HttpHeaderTests {
    private let allocator = TracingAllocator(tracingBytesOf: defaultAllocator)

    internal init() {
        AwsCommonRuntimeKit.initialize()
    }

    internal func testSuite() throws {
        try testCanCreateHttpHeaders()

        assertThat(allocator.count == 0, "Memory was leaked: \(allocator.bytes) bytes in \(allocator.count) allocations")
    }

    private func testCanCreateHttpHeaders() throws {
        let _ = try HttpHeaders(allocator: allocator)
    }
}

try! HttpHeaderTests().testSuite()
