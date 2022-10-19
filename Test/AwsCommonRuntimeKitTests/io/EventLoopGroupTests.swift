//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class EventLoopGroupTests: CrtXCBaseTestCase {

    func testCanCreateGroup() async throws {
        let shutdownWasCalled = XCTestExpectation(description: "Shutdown callback was called")
        _ = try EventLoopGroup(allocator: allocator) {
            shutdownWasCalled.fulfill()
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }

    func testCanCreateGroupWithThreads() throws {
        _ = try EventLoopGroup(threadCount: 2, allocator: allocator)
    }
}
