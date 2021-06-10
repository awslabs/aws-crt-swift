//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class RetryerTests: CrtXCBaseTestCase {
    let expectation = XCTestExpectation(description: "Credentials callback was called")
    
    func testCreateAWSRetryer() throws {
        let shutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }
        let elg = EventLoopGroup(threadCount: 1, allocator: allocator, shutDownOptions: shutDownOptions )
        let backOffRetryOptions = CRTExponentialBackoffRetryOptions(eventLoopGroup: elg)
        let config = MockRetryOptions(backOffRetryOptions: backOffRetryOptions)
        _ = try CRTAWSRetryStrategy(options: config, allocator: allocator)
    }
    
    func testAcquireToken() throws {
        let shutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }
        let elg = EventLoopGroup(threadCount: 1, allocator: allocator, shutDownOptions: shutDownOptions )
        let backOffRetryOptions = CRTExponentialBackoffRetryOptions(eventLoopGroup: elg)
        let config = MockRetryOptions(backOffRetryOptions: backOffRetryOptions)
        let retryer = try CRTAWSRetryStrategy(options: config, allocator: allocator)
        let result = retryer.acquireToken(timeout: 0, partitionId: "partition1")
        result.then { (result) in
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
            case .success(let token):
                print(token)
            }
            self.expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
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
