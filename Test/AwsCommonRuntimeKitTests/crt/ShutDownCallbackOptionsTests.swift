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
            // Encapsulating 
            do {
                let shutDownOptions = ShutDownCallbackOptions(shutDownCallback: { userData in
                    XCTAssertEqual(userData as! String, "hello")
                    closureCalled = true
                }, userData: "hello", allocator: allocator)

                let elg = try EventLoopGroup(allocator: allocator, shutDownOptions: shutDownOptions)
            }

            //Wait for few seconds to make sure callback is triggerred
            try await Task.sleep(nanoseconds: 4_000_000_000)
            XCTAssertTrue(closureCalled)
    }

}
