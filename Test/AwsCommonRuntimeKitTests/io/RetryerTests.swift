//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit
class RetryerTests: XCBaseTestCase {
    let expectation = XCTestExpectation(description: "Credentials callback was called")
    
    func testCreateAWSRetryer() throws {
        let elg = try EventLoopGroup(threadCount: 1)
        _ = try RetryStrategy(eventLoopGroup: elg)
    }
    
    func testAcquireToken() async throws {
        let elg = try EventLoopGroup(threadCount: 1)
        let retryer = try RetryStrategy(eventLoopGroup: elg)
        let result = try await retryer.acquireToken(partitionId: "partition1")
        XCTAssertNotNil(result)
    }

    func testScheduleRetry() async throws {
        let elg = try EventLoopGroup(threadCount: 1)
        let retryer = try RetryStrategy(eventLoopGroup: elg)
        let token = try await retryer.acquireToken(partitionId: "partition1")
        XCTAssertNotNil(token)
        _ = try await retryer.scheduleRetry(token: token, errorType: RetryError.serverError)
    }

    func testShutdownCallback() async throws {
        let shutdownWasCalled = XCTestExpectation(description: "Shutdown callback was called")

        let elg = try EventLoopGroup(threadCount: 1)
        do {
            let retryer = try RetryStrategy(eventLoopGroup: elg, shutdownCallback: {
                shutdownWasCalled.fulfill()
            })
            let token = try await retryer.acquireToken(partitionId: "partition1")
            XCTAssertNotNil(token)
            _ = try await retryer.scheduleRetry(token: token, errorType: RetryError.serverError)
        }
        wait(for: [shutdownWasCalled], timeout: 15)
    }

    func testGenerateRandom() async throws {
        let shutdownWasCalled = XCTestExpectation(description: "Shutdown callback was called")
        let generateRandomWasCalled = XCTestExpectation(description: "Generate random was called")
        let elg = try EventLoopGroup(threadCount: 1)

        do {
            let retryer = try RetryStrategy(
                    eventLoopGroup: elg,
                    generateRandom: {
                        generateRandomWasCalled.fulfill()
                        return UInt64.random(in: 1...UInt64.max)
                    },
                    shutdownCallback: {
                        shutdownWasCalled.fulfill()
                    })
            let token = try await retryer.acquireToken(partitionId: "partition1")
            XCTAssertNotNil(token)
            _ = try await retryer.scheduleRetry(token: token, errorType: RetryError.serverError)
        }
        wait(for: [generateRandomWasCalled, shutdownWasCalled], timeout: 15)
    }
}
