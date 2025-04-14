//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import XCTest

@testable import AwsCommonRuntimeKit

class XCBaseTestCase: XCTestCase {
    internal let tracingAllocator = TracingAllocator(tracingStacksOf: allocator)

    override func setUp() {
        super.setUp()
        // XCode currently lacks a way to enable logs exclusively for failed tests only.
        // To prevent log spamming, we use `error` log level to only print error message.
        // We should update this once a more efficient log processing method becomes available.
        try? Logger.initialize(target: .standardOutput, level: .error)

        // Override the allocator with tracing allocator
        allocator = tracingAllocator.rawValue
        CommonRuntimeKit.initialize()
    }

    override func tearDown() {
        CommonRuntimeKit.cleanUp()

        tracingAllocator.dump()
        XCTAssertEqual(
            tracingAllocator.count, 0,
            "Memory was leaked: \(tracingAllocator.bytes) bytes in \(tracingAllocator.count) allocations"
        )

        super.tearDown()
    }
}

extension XCTestCase {
    func skipTest(message: String) throws {
        throw XCTSkip(message)
    }

    func skipIfiOS() throws {
        #if os(iOS)
            throw XCTSkip("Skipping test on iOS")
        #endif
    }

    func skipifmacOS() throws {
        #if os(macOS)
            throw XCTSkip("Skipping test on macOS")
        #endif
    }

    func skipIfLinux() throws {
        #if os(Linux)
            throw XCTSkip("Skipping test on linux")
        #endif
    }

    func skipIfwatchOS() throws {
        #if os(watchOS)
            throw XCTSkip("Skipping test on watchOS")
        #endif
    }

    func skipIftvOS() throws {
        #if os(tvOS)
            throw XCTSkip("Skipping test on tvOS")
        #endif
    }

    func awaitExpectation(_ expectations: [XCTestExpectation], _ timeout: TimeInterval = 10) async {
        // Remove the Ifdef once our minimum supported Swift version reaches 5.10
        #if swift(>=5.10)
            await fulfillment(of: expectations, timeout: timeout)
        #else
            wait(for: expectations, timeout: timeout)
        #endif
    }
    func skipIfPlatformDoesntSupportTLS() throws {
        // Skipped for secitem support as the unit tests requires enetitlement setup to have acces to
        // the data protection keychain.
        try skipIfiOS()
        try skipIfwatchOS()
        try skipIftvOS()
    }

    /// Return the environment variable value, or Skip the test if env var is not set.
    func getEnvironmentVarOrSkipTest(environmentVarName name: String) throws -> String {
        guard let result = ProcessInfo.processInfo.environment[name] else {
            throw XCTSkip("Skipping test because required environment variable \(name) is missing.")
        }
        return result
    }
}

/*
 * Async Semaphore compatible with Swift's structured concurrency. Swift complains about the normal sync Semaphore since it's a blocking wait.
 * See: https://forums.swift.org/t/semaphore-alternatives-for-structured-concurrency/59353
 */
actor TestSemaphore {
    private var count: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(value: Int = 0) {
        self.count = value
    }

    func wait() async {
        count -= 1
        if count >= 0 { return }
        await withCheckedContinuation {
            waiters.append($0)
        }
    }
    
    func wait(_ timeout: TimeInterval) async {
        count -= 1
        if count >= 0 { return }
        await withCheckedContinuation {
            waiters.append($0)
        }
    }

    func signal(count: Int = 1) {
        assert(count >= 1)
        self.count += count
        for _ in 0..<count {
            if waiters.isEmpty { return }
            waiters.removeFirst().resume()
        }
    }
}
