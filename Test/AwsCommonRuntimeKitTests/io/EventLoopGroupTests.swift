//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class EventLoopGroupTests: CrtXCBaseTestCase {

    func testCanCreateGroup() async throws {
        let shutdownWasCalled = expectation(description: "Shutdown callback was called")
        _ = try EventLoopGroup(allocator: allocator) {
            shutdownWasCalled.fulfill()
        }
        await waitForExpectations(timeout: 15, handler:nil)
    }

    func testCanCreateGroupWithThreads() throws {
        _ = try EventLoopGroup(threadCount: 2, allocator: allocator)
    }
}
