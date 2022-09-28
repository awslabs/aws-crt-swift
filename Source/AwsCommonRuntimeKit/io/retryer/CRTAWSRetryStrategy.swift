//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public final class CRTAWSRetryStrategy {
    let allocator: Allocator

    var rawValue: UnsafeMutablePointer<aws_retry_strategy>

    init(retryStrategy: UnsafeMutablePointer<aws_retry_strategy>,
         allocator: Allocator) {
        rawValue = retryStrategy
        self.allocator = allocator
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

        guard let retryer = aws_retry_strategy_new_standard(allocator.rawValue, &options) else { throw AWSCommonRuntimeError() }

        self.init(retryStrategy: retryer, allocator: allocator)
    }

    public func acquireToken(timeout: UInt64 = 0, partitionId: String) async throws -> CRTAWSRetryToken {
        try await withCheckedThrowingContinuation { (continuation: TokenContinuation) in
            acquireTokenFromCRT(timeout: timeout, partitionId: partitionId, continuation: continuation)
        }
    }

    private func acquireTokenFromCRT(timeout: UInt64, partitionId: String, continuation: TokenContinuation) {
        let callbackData = CRTAcquireTokenCallbackData(allocator: allocator, continuation: continuation)
        let pointer: UnsafeMutablePointer<CRTAcquireTokenCallbackData> = fromPointer(ptr: callbackData)
        let partitionPtr: UnsafeMutablePointer<aws_byte_cursor> = fromPointer(ptr: partitionId.awsByteCursor)
        aws_retry_strategy_acquire_retry_token(rawValue, partitionPtr, { _, errorCode, token, userdata in
            guard let userdata = userdata,
                  let token = token
            else {
                return
            }
            let pointer = userdata.assumingMemoryBound(to: CRTAcquireTokenCallbackData.self)
            defer { pointer.deinitializeAndDeallocate() }
            let error = AWSError(errorCode: errorCode)
            if let continuation = pointer.pointee.continuation {
                if errorCode == 0 {
                    continuation.resume(returning: CRTAWSRetryToken(rawValue: token))
                } else {
                    continuation.resume(throwing: CRTError.crtError(error))
                }
            }
        }, pointer, timeout)
    }

    public func scheduleRetry(token: CRTAWSRetryToken, errorType: CRTRetryError) async throws -> CRTAWSRetryToken {
        try await withCheckedThrowingContinuation { (continuation: ScheduleRetryContinuation) in
            scheduleRetryToCRT(token: token, errorType: errorType, continuation: continuation)
        }
    }

    private func scheduleRetryToCRT(token: CRTAWSRetryToken, errorType: CRTRetryError, continuation _: ScheduleRetryContinuation) {
        let callbackData = CRTScheduleRetryCallbackData(allocator: allocator)
        let pointer: UnsafeMutablePointer<CRTScheduleRetryCallbackData> = fromPointer(ptr: callbackData)

        aws_retry_strategy_schedule_retry(token.rawValue, errorType.rawValue, { retryToken, errorCode, userdata in
            guard let userdata = userdata,
                  let retryToken = retryToken
            else {
                return
            }
            let pointer = userdata.assumingMemoryBound(to: CRTScheduleRetryCallbackData.self)
            defer { pointer.deinitializeAndDeallocate() }
            let error = AWSError(errorCode: errorCode)
            if let continuation = pointer.pointee.continuation {
                if errorCode == 0 {
                    continuation.resume(returning: CRTAWSRetryToken(rawValue: retryToken))
                } else {
                    continuation.resume(throwing: CRTError.crtError(error))
                }
            }
        }, pointer)
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
