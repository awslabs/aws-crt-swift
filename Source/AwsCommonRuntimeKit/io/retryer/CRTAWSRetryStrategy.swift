//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo
//TODO: rename class to CRTAWSRetryStrategy or RetryStrategy. We have inconsistent CRT as a prefix of some classes.
// I am not renaming it for now because it messes up the git change log. Will create a separate PR for just renaming.
public class CRTAWSRetryStrategy {
    let allocator: Allocator
    let rawValue: UnsafeMutablePointer<aws_retry_strategy>

    /// Creates an AWS Retryer implementing the correct retry strategy.
    ///
    /// - Parameters:
    ///   - exponentialBackoffRetryOptions:  The `CRTRetryOptions` options object.
    ///   - initialBucketCapacity: Capacity for partitions. Defaults to 500
    /// - Returns: `CRTAWSRetryStrategy`
    public init(crtRetryOptions: CRTRetryOptions, allocator: Allocator = defaultAllocator) throws {
        self.allocator = allocator
        //TODO: Update generate random
        let exponentialBackOffOptions = aws_exponential_backoff_retry_options(el_group: crtRetryOptions.exponentialBackoffRetryOptions.eventLoopGroup.rawValue,
                                                                              max_retries: crtRetryOptions.exponentialBackoffRetryOptions.maxRetries,
                                                                              backoff_scale_factor_ms: crtRetryOptions.exponentialBackoffRetryOptions.backOffScaleFactor,
                                                                              jitter_mode: crtRetryOptions.exponentialBackoffRetryOptions.jitterMode.rawValue,
                                                                              generate_random: nil)

        var options = aws_standard_retry_options(backoff_retry_options: exponentialBackOffOptions,
                                                 initial_bucket_capacity: crtRetryOptions.initialBucketCapacity)

        guard let rawValue = aws_retry_strategy_new_standard(allocator.rawValue, &options) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    public func acquireToken(timeout: UInt64 = 0, partitionId: String) async throws -> CRTAWSRetryToken {
        return try await withCheckedThrowingContinuation { (continuation: CRTRetryStrategyContinuation) in
            let crtRetryStrategyCore = CRTRetryStrategyCore(continuation: continuation)
            crtRetryStrategyCore.retainedAcquireTokenFromCRT(timeout: timeout, partitionId: partitionId, crtAWSRetryStrategy: self)
        }
    }

    public func scheduleRetry(token: CRTAWSRetryToken, errorType: CRTRetryError) async throws -> CRTAWSRetryToken {
        return try await withCheckedThrowingContinuation({ (continuation: CRTRetryStrategyContinuation) in
            let crtRetryStrategyCore = CRTRetryStrategyCore(continuation: continuation)
            crtRetryStrategyCore.retainedScheduleRetryToCRT(token: token, errorType: errorType)
        })
    }

    /// Records a successful retry.You should always call it after a successful operation
    /// or your system will never recover during an outage.
    public func recordSuccess(token: CRTAWSRetryToken) {
        aws_retry_token_record_success(token.rawValue)
    }

    //TODO: deprecated in SDK. https://github.com/awslabs/aws-crt-swift/issues/66.
    // Need to learn more about this and when to call this. Should this be public etc?
//    public func releaseToken(token: CRTAWSRetryToken) {
//        aws_retry_token_release(token.rawValue)
//    }

    deinit {
        aws_retry_strategy_release(rawValue)
    }
}
