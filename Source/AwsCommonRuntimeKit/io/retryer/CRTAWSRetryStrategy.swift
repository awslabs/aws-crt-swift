//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo
import Foundation

//TODO: rename class to RetryStrategy or CRTRetryStrategy. We have inconsistent CRT/AWS as a prefix of some classes.
// I am not renaming it for now because it messes up the git change log. Will create a separate PR for just renaming.
public class CRTAWSRetryStrategy {
    let rawValue: UnsafeMutablePointer<aws_retry_strategy>

    /// Creates an AWS Retryer implementing the correct retry strategy.
    ///
    /// - Parameters:
    ///   - eventLoopGroup: Event loop group to use for scheduling tasks.
    ///   - initialBucketCapacity: (Optional) Int = 500
    ///   - maxRetries: (Optional) Max retries to allow.
    ///   - backOffScaleFactor: (Optional) Scaling factor to add for the backoff. Default is 25ms and maximum is UInt32.
    ///   - jitterMode: (Optional) Jitter mode to use, see comments for aws_exponential_backoff_jitter_mode.
    ///   - generateRandom: (Optional) By default this will be set to use aws_device_random. If you want something else, set it here.
    ///   - allocator: (Optional) allocator to override.
    /// - Returns: `CRTAWSRetryStrategy`
    public init(eventLoopGroup: EventLoopGroup,
                initialBucketCapacity: Int = 500,
                maxRetries: Int = 10,
                backOffScaleFactor: TimeInterval = 0.025,
                jitterMode: CRTExponentialBackoffJitterMode = .default,
                generateRandom: (@convention(c) () -> UInt64)? = nil,
                allocator: Allocator = defaultAllocator) throws {

        var exponentialBackoffRetryOptions = aws_exponential_backoff_retry_options()
        exponentialBackoffRetryOptions.el_group = eventLoopGroup.rawValue
        exponentialBackoffRetryOptions.max_retries = maxRetries
        exponentialBackoffRetryOptions.backoff_scale_factor_ms = backOffScaleFactor.millisecond > UINT32_MAX
                                                                 ? 25
                                                                 : UInt32(backOffScaleFactor.millisecond)
        exponentialBackoffRetryOptions.jitter_mode = jitterMode.rawValue
        if let generateRandom = generateRandom {
            exponentialBackoffRetryOptions.generate_random = generateRandom
        }

        var standardRetryOptions = aws_standard_retry_options()
        standardRetryOptions.initial_bucket_capacity = initialBucketCapacity
        standardRetryOptions.backoff_retry_options = exponentialBackoffRetryOptions

        guard let rawValue = (withUnsafePointer(to: standardRetryOptions) { retryOptionsPointer in
            return aws_retry_strategy_new_standard(allocator.rawValue, retryOptionsPointer)
        }) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    /// Attempts to acquire a retry token for use with retries. On success, on_acquired will be invoked when a token is
    /// available, or an error will be returned if the timeout expires.
    /// - Parameters:
    ///   - partitionId: (Optional) Partition_id identifies operations that should be grouped together.
    ///                  This allows for more sophisticated strategies such as AIMD and circuit breaker patterns.
    ///                  Pass NULL to use the global partition.
    /// - Returns: `CRTAWSRetryStrategy`
    public func acquireToken(partitionId: String?) async throws -> CRTAWSRetryToken {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CRTAWSRetryToken, Error>) in
            let continuationCore = ContinuationCore(continuation: continuation)
            if withOptionalByteCursorPointerFromString(partitionId, { partitionIdCursorPointer in
                aws_retry_strategy_acquire_retry_token(rawValue,
                        partitionIdCursorPointer,
                        onRetryTokenAcquired,
                        continuationCore.passRetained(),
                        0)
            }) != AWS_OP_SUCCESS {
                continuationCore.release()
                continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
            }
        }
    }

    public func scheduleRetry(token: CRTAWSRetryToken, errorType: CRTRetryError) async throws {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<(), Error>) in
            let continuationCore = ContinuationCore(continuation: continuation)
            if aws_retry_strategy_schedule_retry(token.rawValue,
                    errorType.rawValue,
                    onRetryReady,
                    continuationCore.passRetained()) != AWS_OP_SUCCESS {
                continuationCore.release()
                continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
            }
        })
    }

    /// Records a successful retry.You should always call it after a successful operation
    /// or your system will never recover during an outage.
    public func recordSuccess(token: CRTAWSRetryToken) {
        aws_retry_token_record_success(token.rawValue)
    }

    deinit {
        aws_retry_strategy_release(rawValue)
    }
}

private func onRetryReady(token: UnsafeMutablePointer<aws_retry_token>?,
                          errorCode: Int32,
                          userData: UnsafeMutableRawPointer!) {
    let crtRetryStrategyCore = Unmanaged<ContinuationCore<()>>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        crtRetryStrategyCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    crtRetryStrategyCore.continuation.resume()
}

private func onRetryTokenAcquired(retry_strategy: UnsafeMutablePointer<aws_retry_strategy>?,
                                  errorCode: Int32,
                                  token: UnsafeMutablePointer<aws_retry_token>?,
                                  userData: UnsafeMutableRawPointer!) {
    let crtRetryStrategyCore = Unmanaged<ContinuationCore<CRTAWSRetryToken>>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        crtRetryStrategyCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    crtRetryStrategyCore.continuation.resume(returning: CRTAWSRetryToken(rawValue: token!))
}
