@testable
import AwsCommonRuntimeKit
import Foundation

fileprivate func assertThat(_ condition: Bool, _ message: @autoclosure () -> String = "Assertion failed", file: StaticString = #file, line: UInt = #line) {
  if (!condition) {
    print("Assertion failed: \(message()); \(file):\(line)")
    exit(-1)
  }
}

internal class BootstrapTests {
  private let allocator = TracingAllocator(tracingBytesOf: defaultAllocator)

  internal init() {
    AwsCommonRuntimeKit.initialize()
  }

  internal func testSuite() throws {
    try doesNotLeakMemory()

    assertThat(allocator.count == 0, "Memory was leaked: \(allocator.bytes) bytes in \(allocator.count) allocations")
  }

  private func doesNotLeakMemory() throws {
    let elg = try EventLoopGroup(allocator: allocator)
    let resolver = try DefaultHostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30, allocator: allocator)
    let _ = try ClientBootstrap(eventLoopGroup: elg, hostResolver: resolver, allocator: allocator)
  }
}

try! BootstrapTests().testSuite()
