//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class BootstrapTests: XCBaseTestCase {

  func testCanCreateBootstrap() throws {
    let elg = try EventLoopGroup()
    let resolver = try HostResolver(eventLoopGroup: elg,
                                           maxHosts: 8,
                                           maxTTL: 30)

    _ = try ClientBootstrap(eventLoopGroup: elg,
                            hostResolver: resolver)
  }

  func testBootstrapShutdownCallback() async throws {
    let shutdownWasCalled = XCTestExpectation(description: "Shutdown callback was called")
    shutdownWasCalled.expectedFulfillmentCount = 3
    let shutdownCallback =  {
      shutdownWasCalled.fulfill()
    }

    do {
      let elg = try EventLoopGroup(shutdownCallback: shutdownCallback)
      let resolver = try HostResolver(eventLoopGroup: elg,
              maxHosts: 8,
              maxTTL: 30,
              shutdownCallback: shutdownCallback)

      _ = try ClientBootstrap(eventLoopGroup: elg,
              hostResolver: resolver,
              shutdownCallback: shutdownCallback)
    }
    await fulfillment(of: [shutdownWasCalled], timeout: 15)
  }
}
