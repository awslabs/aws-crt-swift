//
// Created by Khan, Waqar Ahmed on 10/15/22.
//

import XCTest
@testable import AwsCommonRuntimeKit
import Foundation
import Darwin
class ShutDownCallbackOptionsTests: CrtXCBaseTestCase {

    func testShutdownCallback() async throws {
        let shutdownWasCalled = expectation(description: "Shutdown callback was called")
            // Encapsulating 
            do {
                let shutDownOptions = ShutDownCallbackOptions(allocator: allocator) {
                    shutdownWasCalled.fulfill()
                }

                _ = try EventLoopGroup(allocator: allocator, shutDownOptions: shutDownOptions)
            }
        await waitForExpectations(timeout: 10, handler:nil)
    }

}
