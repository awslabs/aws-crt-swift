//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit
//TODO: write more tests
class RetryerTests: CrtXCBaseTestCase {
    let expectation = XCTestExpectation(description: "Credentials callback was called")
    
    func testCreateAWSRetryer() throws {
        let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
        let exponentialBackoffRetryOptions = CRTExponentialBackoffRetryOptions(eventLoopGroup: elg)
        let config = MockRetryOptions(exponentialBackoffRetryOptions: exponentialBackoffRetryOptions)
        _ = try CRTAWSRetryStrategy(crtRetryOptions: config, allocator: allocator)
    }
    
    func testAcquireToken() async throws {
        let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
        let exponentialBackoffRetryOptions = CRTExponentialBackoffRetryOptions(eventLoopGroup: elg)
        let config = MockRetryOptions(exponentialBackoffRetryOptions: exponentialBackoffRetryOptions)
        let retryer = try CRTAWSRetryStrategy(crtRetryOptions: config, allocator: allocator)
        let result = try await retryer.acquireToken(timeout: 0, partitionId: "partition1")
        XCTAssertNotNil(result)
    }
}

struct MockRetryOptions: CRTRetryOptions {
    var initialBucketCapacity: Int
    var exponentialBackoffRetryOptions: CRTExponentialBackoffRetryOptions
    
    public init(initialBucketCapacity: Int = 500,
                exponentialBackoffRetryOptions: CRTExponentialBackoffRetryOptions) {
        self.initialBucketCapacity = initialBucketCapacity
        self.exponentialBackoffRetryOptions = exponentialBackoffRetryOptions
    }
}
