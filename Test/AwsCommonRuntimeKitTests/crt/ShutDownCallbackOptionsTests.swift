//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class ShutdownCallbackOptionsTests: XCBaseTestCase {

    func testShutdownCallback() async throws {
        let shutdownWasCalled = XCTestExpectation(description: "Shutdown callback was called")
        do {
            _ = try EventLoopGroup {
                shutdownWasCalled.fulfill()
            }
        }
        await fulfillment(of: [shutdownWasCalled], timeout: 15)
    }
}
