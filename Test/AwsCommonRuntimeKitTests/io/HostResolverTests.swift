//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class HostResolverTests: XCBaseTestCase {
    
    func testCanResolveHosts() async throws {
        let elg = try EventLoopGroup(allocator: allocator)
        let resolver = try HostResolver(eventLoopGroup: elg,
                                           maxHosts: 8,
                                           maxTTL: 5,
                                           allocator: allocator)
        
        let addresses = try await resolver.resolveAddress(args: HostResolverArguments(hostName: "localhost"))
        XCTAssertNoThrow(addresses)
        XCTAssertNotNil(addresses.count)
        XCTAssert(addresses.count >= 1, "Address Count is (\(String(describing: addresses.count)))")
    }

    func testPurgeCache() async throws {
        let elg = try EventLoopGroup(allocator: allocator)
        let resolver = try HostResolver(eventLoopGroup: elg,
                maxHosts: 8,
                maxTTL: 5,
                allocator: allocator)

        var addresses = try await resolver.resolveAddress(args: HostResolverArguments(hostName: "localhost"))
        XCTAssert(addresses.count >= 1, "Address Count is (\(String(describing: addresses.count)))")
        try await resolver.purgeCache(args: HostResolverArguments(hostName: "localHost"))
        try await resolver.purgeCache(args: HostResolverArguments(hostName: "localHost"))
        addresses = try await resolver.resolveAddress(args: HostResolverArguments(hostName: "localhost"))
        XCTAssert(addresses.count >= 1, "Address Count is (\(String(describing: addresses.count)))")
        try await resolver.purgeCache()
        try await resolver.purgeCache()
        addresses = try await resolver.resolveAddress(args: HostResolverArguments(hostName: "localhost"))
        XCTAssert(addresses.count >= 1, "Address Count is (\(String(describing: addresses.count)))")
    }

    func testReportConnectionOnFailure() async throws {
        let elg = try EventLoopGroup(allocator: allocator)
        let resolver = try HostResolver(eventLoopGroup: elg,
                maxHosts: 8,
                maxTTL: 5,
                allocator: allocator)

        var addresses = try await resolver.resolveAddress(args: HostResolverArguments(hostName: "localhost"))
        XCTAssert(addresses.count >= 1, "Address Count is (\(String(describing: addresses.count)))")
        try resolver.reportFailureOnAddress(address: addresses[0])
        addresses = try await resolver.resolveAddress(args: HostResolverArguments(hostName: "localhost"))
        XCTAssert(addresses.count >= 1, "Address Count is (\(String(describing: addresses.count)))")
    }

    func testHotResolverShutdownCallback() async throws {
        let shutdownWasCalled = XCTestExpectation(description: "Shutdown callback was called")
        shutdownWasCalled.expectedFulfillmentCount = 2
        let shutdownCallback = {
            shutdownWasCalled.fulfill()
        }
        do {
            let elg = try EventLoopGroup(allocator: self.allocator, shutdownCallback: shutdownCallback)
            _ = try HostResolver(eventLoopGroup: elg,
                    maxHosts: 8,
                    maxTTL: 5,
                    allocator: self.allocator,
                    shutdownCallback: shutdownCallback)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }
}
