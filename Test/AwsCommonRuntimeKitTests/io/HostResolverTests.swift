//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class HostResolverTests: CrtXCBaseTestCase {

  func testCanResolveHosts() throws {
    let shutDownOptions = ShutDownCallbackOptions() { semaphore in
        semaphore.signal()
    }
    
    let resolverShutDownOptions = ShutDownCallbackOptions() { semaphore in
        semaphore.signal()
    }
   
    let elg = try EventLoopGroup(allocator: allocator, shutDownOptions: shutDownOptions)
    
    let resolver = try DefaultHostResolver(eventLoopGroup: elg,
                                           maxHosts: 8,
                                           maxTTL: 5,
                                           allocator: allocator,
                                           shutDownOptions: resolverShutDownOptions)

    var addressCount: Int?
    var error: Int32?
    let semaphore = DispatchSemaphore(value: 0)

    try resolver.resolve(host: "localhost", onResolved: { (_, addresses, errorCode) in
      addressCount = addresses.count
      error = errorCode

      semaphore.signal()
    })

    semaphore.wait()
    XCTAssertNotNil(error)
    XCTAssertNotNil(addressCount)
    XCTAssertEqual(error, 0, "Error (\(String(describing: error)) is blank")
    XCTAssertEqual(addressCount, 2, "Address Count is (\(String(describing: addressCount)))")
  }
}
