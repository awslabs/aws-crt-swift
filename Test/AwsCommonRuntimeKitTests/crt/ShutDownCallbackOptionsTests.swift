//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class ShutDownCallbackOptionsTests: CrtXCBaseTestCase {

    func testShutdownCallback() async throws {
        let shutdownWasCalled = expectation(description: "Shutdown callback was called")
        do {
            _ = try EventLoopGroup {
                shutdownWasCalled.fulfill()
            }
        }
        await waitForExpectations(timeout: 15, handler:nil)
    }

}
