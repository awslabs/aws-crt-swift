//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
@testable
import AwsCommonRuntimeKit
import Foundation

fileprivate func assertThat(_ condition: Bool, _ message: @autoclosure () -> String = "Assertion failed", file: StaticString = #file, line: UInt = #line) {
  if (!condition) {
    print("Assertion failed: \(message()); \(file):\(line)")
    exit(-1)
  }
}

internal class TracingAllocatorTests {
  internal func testSuite() throws {
    try testTracingAllocatorCorrectlyTracesAllocations()
  }

  private func testTracingAllocatorCorrectlyTracesAllocations() throws {
    let allocator = TracingAllocator(tracingBytesOf: defaultAllocator)
    assertThat(allocator.bytes == 0)
    assertThat(allocator.count == 0)

    let ptr1: UnsafeMutablePointer<UInt32> = try allocator.allocate(capacity: 5)
    assertThat(allocator.bytes == 20)
    assertThat(allocator.count == 1)

    let ptr2: UnsafeMutablePointer<UInt8> = try allocator.allocate(capacity: 1_024)
    assertThat(allocator.bytes == 1_044)
    assertThat(allocator.count == 2)

    allocator.release(ptr1)
    assertThat(allocator.bytes == 1_024)
    assertThat(allocator.count == 1)

    allocator.release(ptr2)
    assertThat(allocator.bytes == 0)
    assertThat(allocator.count == 0)
  }
}

try! TracingAllocatorTests().testSuite()
