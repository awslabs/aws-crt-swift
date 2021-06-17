//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public final class CRTAWSRetryStrategy {
    let allocator: Allocator

    var rawValue: UnsafeMutablePointer<aws_retry_strategy>

    init(retryStrategy: UnsafeMutablePointer<aws_retry_strategy>,
         allocator: Allocator) {
        self.rawValue = retryStrategy
        self.allocator = allocator
    }

    public convenience init(fromProvider impl: CRTRetryStrategy,
                            allocator: Allocator = defaultAllocator) {
        let wrapped = WrappedCRTRetryStrategy(impl: impl, allocator: allocator)
        self.init(retryStrategy: &wrapped.rawValue, allocator: wrapped.allocator)
    }

    /// Creates an AWS Retryer implementing the correct retry strategy.
    ///
    /// - Parameters:
    ///   - options:  The `CRTRetryOptions` options object.
    /// - Returns: `CRTAWSRetryStrategy`
    public convenience init(options: CRTRetryOptions,
                            allocator: Allocator = defaultAllocator) throws {

        let exponentialBackOffOptions = aws_exponential_backoff_retry_options(el_group: options.backOffRetryOptions.eventLoopGroup.rawValue,
                                                                              max_retries: options.backOffRetryOptions.maxRetries,
                                                                              backoff_scale_factor_ms: options.backOffRetryOptions.backOffScaleFactor,
                                                                              jitter_mode: options.backOffRetryOptions.jitterMode.rawValue,
                                                                              generate_random: nil)

        var options = aws_standard_retry_options(backoff_retry_options: exponentialBackOffOptions,
                                                 initial_bucket_capacity: options.initialBucketCapacity)

        guard let retryer = aws_retry_strategy_new_standard(allocator.rawValue, &options) else {throw AWSCommonRuntimeError()}

        self.init(retryStrategy: retryer, allocator: allocator)
    }

    public func acquireToken(timeout: UInt64 = 0, partitionId: String) -> Future<CRTAWSRetryToken> {
        let future = Future<CRTAWSRetryToken>()
        let callbackData = CRTAcquireTokenCallbackData(allocator: allocator) { (crtToken, crtError) in
            if let crtToken = crtToken {
                future.fulfill(crtToken)
            } else {
                future.fail(crtError)
            }
        }

        let pointer = UnsafeMutablePointer<CRTAcquireTokenCallbackData>.allocate(capacity: 1)
        pointer.initialize(to: callbackData)
        let partitionPtr = UnsafeMutablePointer<aws_byte_cursor>.allocate(capacity: 1)
        partitionPtr.initialize(to: partitionId.awsByteCursor)
        aws_retry_strategy_acquire_retry_token(rawValue, partitionPtr, { retryerPointer, errorCode, token, userdata in
            guard let userdata = userdata,
                  let token = token else {
                return
            }
            let pointer = userdata.assumingMemoryBound(to: CRTAcquireTokenCallbackData.self)
            defer {pointer.deinitializeAndDeallocate()}
            let error = AWSError(errorCode: errorCode)
            if let onTokenAcquired = pointer.pointee.onTokenAcquired {
                onTokenAcquired(CRTAWSRetryToken(rawValue: token), CRTError.crtError(error))
            }
        }, pointer, timeout)
        return future
    }

    public func scheduleRetry(token: CRTAWSRetryToken, errorType: CRTRetryError) -> Future<CRTAWSRetryToken> {
        let future = Future<CRTAWSRetryToken>()
        let callbackData = CRTScheduleRetryCallbackData(allocator: allocator) { crtToken, crtError in
            if let crtToken = crtToken {
                future.fulfill(crtToken)
            } else {
                future.fail(crtError)
            }
        }

        let pointer = UnsafeMutablePointer<CRTScheduleRetryCallbackData>.allocate(capacity: 1)
        pointer.initialize(to: callbackData)

        aws_retry_strategy_schedule_retry(token.rawValue, errorType.rawValue, { retryToken, errorCode, userdata in
            guard let userdata = userdata,
                  let retryToken = retryToken else {
                return
            }
            let pointer = userdata.assumingMemoryBound(to: CRTScheduleRetryCallbackData.self)
            defer { pointer.deinitializeAndDeallocate()}
            let error = AWSError(errorCode: errorCode)
            if let onRetryReady = pointer.pointee.onRetryReady {
                onRetryReady(CRTAWSRetryToken(rawValue: retryToken), CRTError.crtError(error))
            }
        }, pointer)
        return future
    }

    public func recordSuccess(token: CRTAWSRetryToken) {
        aws_retry_token_record_success(token.rawValue)
    }

    public func releaseToken(token: CRTAWSRetryToken) {
        aws_retry_token_release(token.rawValue)
    }

    deinit {
        aws_retry_strategy_release(rawValue)
    }
}
