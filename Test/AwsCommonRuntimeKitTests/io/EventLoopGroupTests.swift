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
  private let allocator = TracingAllocator(tracingBytesOf: defaultAllocator)

  internal init() {
    AwsCommonRuntimeKit.initialize()
  }

  internal func testSuite() throws {
    try testCanCreateGroup()

    assertThat(allocator.count == 0, "Memory was leaked: \(allocator.bytes) bytes in \(allocator.count) allocations")
  }

  private func testCanCreateGroup() throws {
    let _ = try EventLoopGroup(allocator: allocator)
  }

  private func testCanCreateGroupWithThreads() throws {
    let _ = try EventLoopGroup(threadCount: 2, allocator: allocator)
  }
}

try! TracingAllocatorTests().testSuite()
