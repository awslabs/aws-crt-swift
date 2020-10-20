//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class BootstrapTests: CrtXCBaseTestCase {

  func testCanCreateBootstrap() throws {
    let shutDownOptions = ShutDownCallbackOptions() { semaphore in
        semaphore.signal()
    }
    let resolverShutDownOptions = ShutDownCallbackOptions() { semaphore in
        semaphore.signal()
    }
    let elg = try EventLoopGroup(allocator: allocator, shutDownOptions: shutDownOptions)
    let resolver = try DefaultHostResolver(eventLoopGroup: elg,
                                           maxHosts: 8,
                                           maxTTL: 30,
                                           allocator: allocator,
                                           shutDownOptions: resolverShutDownOptions)
    let clientBootstrapCallbackData = ClientBootstrapCallbackData { sempahore in
        sempahore.signal()
    }
    _ = try ClientBootstrap(eventLoopGroup: elg,
                            hostResolver: resolver,
                            callbackData: clientBootstrapCallbackData,
                            allocator: allocator)
  }
}
