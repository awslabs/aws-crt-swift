//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class HostResolverTests: CrtXCBaseTestCase {
    
    func testCanResolveHosts() async throws {
        let elg = EventLoopGroup(allocator: self.allocator)
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
}
