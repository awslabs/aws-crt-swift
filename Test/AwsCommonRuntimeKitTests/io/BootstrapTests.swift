//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class BootstrapTests: CrtXCBaseTestCase {

  func testCanCreateBootstrap() throws {
    let elg = try EventLoopGroup(allocator: allocator)
    let resolver = try HostResolver(eventLoopGroup: elg,
                                           maxHosts: 8,
                                           maxTTL: 30,
                                           allocator: allocator)

    _ = try ClientBootstrap(eventLoopGroup: elg,
                            hostResolver: resolver,
                            allocator: allocator)
  }

  func testBootstrapShutdownCallback() async throws {
    let shutdownWasCalled = XCTestExpectation(description: "Shutdown callback was called")
    shutdownWasCalled.expectedFulfillmentCount = 3
    let shutdownCallback =  {
      shutdownWasCalled.fulfill()
    }

    do {
      let elg = try EventLoopGroup(allocator: allocator, shutdownCallback: shutdownCallback)
      let resolver = try HostResolver(eventLoopGroup: elg,
              maxHosts: 8,
              maxTTL: 30,
              allocator: allocator,
              shutdownCallback: shutdownCallback)

      _ = try ClientBootstrap(eventLoopGroup: elg,
              hostResolver: resolver,
              allocator: allocator,
              shutdownCallback: shutdownCallback)
    }
    wait(for: [shutdownWasCalled], timeout: 15)
  }
}
