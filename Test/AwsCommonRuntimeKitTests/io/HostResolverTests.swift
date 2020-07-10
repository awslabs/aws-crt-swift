//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
@testable
import AwsCommonRuntimeKit
import Foundation

//fileprivate func assertThat(_ condition: Bool, _ message: @autoclosure () -> String = "Assertion failed", file: StaticString = #file, line: UInt = #line) {
//  if (!condition) {
//    print("Assertion failed: \(message()); \(file):\(line)")
//    exit(-1)
//  }
//}

internal class HostResolverTests {
  private let allocator = TracingAllocator(tracingBytesOf: defaultAllocator)

  internal init() {
    AwsCommonRuntimeKit.initialize()
  }

  internal func testSuite() throws {
    try canResolveHosts()

    assertThat(allocator.count == 0, "Memory was leaked: \(allocator.bytes) bytes in \(allocator.count) allocations")
  }

  private func canResolveHosts() throws {
    let elg = try EventLoopGroup(allocator: allocator)
    let resolver = try DefaultHostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 5, allocator: allocator)

    let semaphore = DispatchSemaphore(value: 0)

    var addressCount: Int?
    var error: Int32?
    try resolver.resolve(host: "localhost", onResolved: { (resolver, addresses, errorCode) in
      semaphore.signal()
    })

    semaphore.wait()

    try resolver.resolve(host: "localhost", onResolved: { (resolver, addresses, errorCode) in
      addressCount = addresses.count
      error = errorCode

      semaphore.signal()
    })

    semaphore.wait()

    assertThat(error ?? 0 != 0 || addressCount ?? 0 != 0,
      "Both error (\(String(describing: error))) and addressCount (\(String(describing: addressCount))) are blank")
  }
}

try! HostResolverTests().testSuite()
