//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest

@testable import AwsCommonRuntimeKit

class HostResolverTests: XCBaseTestCase {

  func testCanResolveHosts() async throws {
    let elg = try EventLoopGroup()
    let resolver = try HostResolver(
      eventLoopGroup: elg,
      maxHosts: 8,
      maxTTL: 5)

    let addresses = try await resolver.resolveAddress(
      args: HostResolverArguments(hostName: "localhost"))
    XCTAssertNoThrow(addresses)
    XCTAssertNotNil(addresses.count)
    XCTAssert(addresses.count >= 1, "Address Count is (\(String(describing: addresses.count)))")
  }

  func testPurgeCache() async throws {
    let elg = try EventLoopGroup()
    let resolver = try HostResolver(
      eventLoopGroup: elg,
      maxHosts: 8,
      maxTTL: 5)

    var addresses = try await resolver.resolveAddress(
      args: HostResolverArguments(hostName: "localhost"))
    XCTAssert(addresses.count >= 1, "Address Count is (\(String(describing: addresses.count)))")
    await resolver.purgeCache(args: HostResolverArguments(hostName: "localHost"))
    await resolver.purgeCache(args: HostResolverArguments(hostName: "localHost"))
    addresses = try await resolver.resolveAddress(
      args: HostResolverArguments(hostName: "localhost"))
    XCTAssert(addresses.count >= 1, "Address Count is (\(String(describing: addresses.count)))")
    await resolver.purgeCache()
    await resolver.purgeCache()
    addresses = try await resolver.resolveAddress(
      args: HostResolverArguments(hostName: "localhost"))
    XCTAssert(addresses.count >= 1, "Address Count is (\(String(describing: addresses.count)))")
  }

  func testReportConnectionOnFailure() async throws {
    let elg = try EventLoopGroup()
    let resolver = try HostResolver(
      eventLoopGroup: elg,
      maxHosts: 8,
      maxTTL: 5)

    var addresses = try await resolver.resolveAddress(
      args: HostResolverArguments(hostName: "localhost"))
    XCTAssert(addresses.count >= 1, "Address Count is (\(String(describing: addresses.count)))")
    resolver.reportFailureOnAddress(address: addresses[0])
    addresses = try await resolver.resolveAddress(
      args: HostResolverArguments(hostName: "localhost"))
    XCTAssert(addresses.count >= 1, "Address Count is (\(String(describing: addresses.count)))")
  }

  func testHotResolverShutdownCallback() async throws {
    let shutdownWasCalled = XCTestExpectation(description: "Shutdown callback was called")
    shutdownWasCalled.expectedFulfillmentCount = 2
    let shutdownCallback = {
      shutdownWasCalled.fulfill()
    }
    do {
      let elg = try EventLoopGroup(shutdownCallback: shutdownCallback)
      _ = try HostResolver(
        eventLoopGroup: elg,
        maxHosts: 8,
        maxTTL: 5,
        shutdownCallback: shutdownCallback)
    }
    await awaitExpectation([shutdownWasCalled])
  }
}
