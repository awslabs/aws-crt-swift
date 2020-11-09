//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class HostResolverTests: CrtXCBaseTestCase {

  func testCanResolveHosts() throws {
    let shutDownOptions = ShutDownCallbackOptions { semaphore in
        semaphore.signal()
    }

    let resolverShutDownOptions = ShutDownCallbackOptions { semaphore in
        semaphore.signal()
    }

    let elg = EventLoopGroup(allocator: allocator, shutDownOptions: shutDownOptions)

    let resolver = DefaultHostResolver(eventLoopGroup: elg,
                                           maxHosts: 8,
                                           maxTTL: 5,
                                           allocator: allocator,
                                           shutDownOptions: resolverShutDownOptions)

    var addressCount: Int?
    var error: CRTError?
    let semaphore = DispatchSemaphore(value: 0)

    try resolver.resolve(host: "localhost", onResolved: { (_, addresses, crtError) in
      addressCount = addresses.count
      error = crtError

      semaphore.signal()
    })

    semaphore.wait()
    XCTAssertNotNil(error)
    XCTAssertNotNil(addressCount)
    if case let CRTError.crtError(unwrappedError) = error.unsafelyUnwrapped {
        XCTAssertEqual(unwrappedError.errorCode, 0, "Error (\(String(describing: unwrappedError)) is blank")
    }

    XCTAssertEqual(addressCount, 2, "Address Count is (\(String(describing: addressCount)))")
  }
}
