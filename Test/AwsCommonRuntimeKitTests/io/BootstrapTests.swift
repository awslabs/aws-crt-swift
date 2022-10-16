//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class BootstrapTests: CrtXCBaseTestCase {

  func testCanCreateBootstrap() throws {
    //TODO: resolve
//    let shutDownOptions = ShutDownCallbackOptions { semaphore in
//        semaphore.signal()
//    }
//    let resolverShutDownOptions = ShutDownCallbackOptions { semaphore in
//        semaphore.signal()
//    }
    let elg = try EventLoopGroup(allocator: allocator, shutDownOptions: nil)
    let resolver = DefaultHostResolver(eventLoopGroup: elg,
                                           maxHosts: 8,
                                           maxTTL: 30,
                                           allocator: allocator,
                                           shutDownOptions: nil)

    _ = try ClientBootstrap(eventLoopGroup: elg,
                            hostResolver: resolver,
                            callbackData: nil,
                            allocator: allocator)
  }
}
