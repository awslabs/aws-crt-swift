//
// Created by Khan, Waqar Ahmed on 10/15/22.
//

import XCTest
@testable import AwsCommonRuntimeKit
import Foundation
import Darwin
class ShutDownCallbackOptionsTests: CrtXCBaseTestCase {

    func testShutdownCallback() async throws {
            var closureCalled = false
            let userData = "hello"
            // Encapsulating 
            do {
                let shutDownOptions = ShutDownCallbackOptions(allocator: allocator) {
                    XCTAssertEqual(userData, "hello")
                    closureCalled = true
                }

                _ = try EventLoopGroup(allocator: allocator, shutDownOptions: shutDownOptions)
            }

            //Wait for few seconds to make sure callback is triggerred
            try await Task.sleep(nanoseconds: 4_000_000_000)
            XCTAssertTrue(closureCalled)
    }

}
