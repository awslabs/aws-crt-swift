//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit
//TODO: write more tests
class RetryerTests: CrtXCBaseTestCase {
    let expectation = XCTestExpectation(description: "Credentials callback was called")
    
    func testCreateAWSRetryer() throws {
        let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
        _ = try CRTAWSRetryStrategy(eventLoopGroup: elg, allocator: allocator)
    }
    
    func testAcquireToken() async throws {
        let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
        let retryer = try CRTAWSRetryStrategy(eventLoopGroup: elg, allocator: allocator)
        let result = try await retryer.acquireToken(partitionId: "partition1")
        XCTAssertNotNil(result)
    }

    func testSechudleRetry() async throws {
        let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
        let retryer = try CRTAWSRetryStrategy(eventLoopGroup: elg, allocator: allocator)
        let token = try await retryer.acquireToken(partitionId: "partition1")
        XCTAssertNotNil(token)
        try await retryer.scheduleRetry(token: token, errorType: CRTRetryError.serverError)
    }
}
