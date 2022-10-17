//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class HostResolverTests: CrtXCBaseTestCase {
    
    func testCanResolveHosts() async throws {
        let elg = try EventLoopGroup(allocator: self.allocator)
        let resolver = DefaultHostResolver(eventLoopGroup: elg,
                                           maxHosts: 8,
                                           maxTTL: 5,
                                           allocator: self.allocator,
                                           shutDownOptions: nil)
        
        let addresses = try await resolver.resolve(host: "localhost")
        XCTAssertNoThrow(addresses)
        XCTAssertNotNil(addresses.count)
        XCTAssert(addresses.count >= 1, "Address Count is (\(String(describing: addresses.count)))")
    }

    func testHotResolverShutdownCallback() async throws {
        let shutdownWasCalled = expectation(description: "Shutdown callback was called")
        let shutDownOptions = ShutDownCallbackOptions(allocator: allocator) {
            shutdownWasCalled.fulfill()
        }
        do {
            let elg = try EventLoopGroup(allocator: self.allocator)
            _ = DefaultHostResolver(eventLoopGroup: elg,
                    maxHosts: 8,
                    maxTTL: 5,
                    allocator: self.allocator,
                    shutDownOptions: shutDownOptions)
        }
        await waitForExpectations(timeout: 10, handler:nil)
    }
}
