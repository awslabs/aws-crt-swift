//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class RetryerTests: CrtXCBaseTestCase {
    let expectation = XCTestExpectation(description: "Credentials callback was called")
    
    func testCreateAWSRetryer() throws {
        let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
        let backOffRetryOptions = CRTExponentialBackoffRetryOptions(eventLoopGroup: elg)
        let config = MockRetryOptions(backOffRetryOptions: backOffRetryOptions)
        _ = try CRTAWSRetryStrategy(options: config, allocator: allocator)
    }
    
    func testAcquireToken() async throws {
        let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
        let backOffRetryOptions = CRTExponentialBackoffRetryOptions(eventLoopGroup: elg)
        let config = MockRetryOptions(backOffRetryOptions: backOffRetryOptions)
        let retryer = try CRTAWSRetryStrategy(options: config, allocator: allocator)
        let result = try await retryer.acquireToken(timeout: 0, partitionId: "partition1")
        XCTAssertNotNil(result)
    }
}

struct MockRetryOptions: CRTRetryOptions {
    var initialBucketCapacity: Int
    var backOffRetryOptions: CRTExponentialBackoffRetryOptions
    
    public init(initialBucketCapacity: Int = 500,
                backOffRetryOptions: CRTExponentialBackoffRetryOptions) {
        self.initialBucketCapacity = initialBucketCapacity
        self.backOffRetryOptions = backOffRetryOptions
    }
}
