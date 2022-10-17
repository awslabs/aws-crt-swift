//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class BootstrapTests: CrtXCBaseTestCase {

  func testCanCreateBootstrap() throws {
    let elg = try EventLoopGroup(allocator: allocator, shutDownOptions: nil)
    let resolver = DefaultHostResolver(eventLoopGroup: elg,
                                           maxHosts: 8,
                                           maxTTL: 30,
                                           allocator: allocator,
                                           shutDownOptions: nil)

    _ = try ClientBootstrap(eventLoopGroup: elg,
                            hostResolver: resolver,
                            shutDownCallbackOptions: nil,
                            allocator: allocator)
  }

  func testBootstrapShutdownCallback2() async throws {
    let shutdownWasCalled = expectation(description: "Shutdown callback was called")
    shutdownWasCalled.expectedFulfillmentCount = 3
    let shutDownCallbackOptions = ShutDownCallbackOptions(allocator: allocator) {
      shutdownWasCalled.fulfill()
    }

    do {
      let elg = try EventLoopGroup(allocator: allocator, shutDownOptions: shutDownCallbackOptions)
      let resolver = DefaultHostResolver(eventLoopGroup: elg,
              maxHosts: 8,
              maxTTL: 30,
              allocator: allocator,
              shutDownOptions: shutDownCallbackOptions)

      let bt = try ClientBootstrap(eventLoopGroup: elg,
              hostResolver: resolver,
              shutDownCallbackOptions: shutDownCallbackOptions,
              allocator: allocator)
    }
    await waitForExpectations(timeout: 10, handler:nil)
  }

}
