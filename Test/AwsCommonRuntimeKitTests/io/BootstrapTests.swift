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

  func testBootstrapShutdownCallback() async throws {
    var closureCalled = false
    let userData = "hello"
    let shutDownOptions = ShutDownCallbackOptions(allocator: allocator) {
      XCTAssertEqual(userData, "hello")
      closureCalled = true
    }

    do {
      let elg = try EventLoopGroup(allocator: allocator, shutDownOptions: nil)
      let resolver = DefaultHostResolver(eventLoopGroup: elg,
              maxHosts: 8,
              maxTTL: 30,
              allocator: allocator,
              shutDownOptions: nil)

      _ = try ClientBootstrap(eventLoopGroup: elg,
              hostResolver: resolver,
              shutDownCallbackOptions: shutDownOptions,
              allocator: allocator)
    }

    //Wait for few seconds to make sure callback is triggerred
    try await Task.sleep(nanoseconds: 4_000_000_000)
    XCTAssertTrue(closureCalled)
  }
}
