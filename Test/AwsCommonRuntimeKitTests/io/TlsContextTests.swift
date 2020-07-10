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

internal class TlsContextTests {
  private let allocator = TracingAllocator(tracingBytesOf: defaultAllocator)

  internal init() {
    AwsCommonRuntimeKit.initialize()
  }

  internal func testSuite() throws {
    try doesNotLeakMemory()

    assertThat(allocator.count == 0, "Memory was leaked: \(allocator.bytes) bytes in \(allocator.count) allocations")
  }

  private func doesNotLeakMemory() throws {
    let options = TlsContextOptions(defaultClientWithAllocator: allocator)
    let context = try TlsContext(options: options, mode: .client, allocator: allocator)
    let _ = context.newConnectionOptions()
  }
}

try! TlsContextTests().testSuite()
