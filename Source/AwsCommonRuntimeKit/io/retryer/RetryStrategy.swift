//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo
import Foundation

public class RetryStrategy {
    let rawValue: UnsafeMutablePointer<aws_retry_strategy>

    /// Creates an AWS Retryer implementing the correct retry strategy.
    ///
    /// - Parameters:
    ///   - eventLoopGroup: Event loop group to use for scheduling tasks.
    ///   - initialBucketCapacity: (Optional) Int = 500
    ///   - maxRetries: (Optional) Max retries to allow.
    ///   - backOffScaleFactor: (Optional) Scaling factor to add for the backoff. Default is 25ms and maximum is UInt32 ms.
    ///   - jitterMode: (Optional) Jitter mode to use, see comments for aws_exponential_backoff_jitter_mode.
    ///   - generateRandom: (Optional) By default this will be set to use aws_device_random. If you want something else, set it here.
    ///   - shutdownCallback: (Optional) Shutdown callback to invoke when the resource is cleaned up.
    ///   - allocator: (Optional) allocator to override.
    /// - Returns: `CRTAWSRetryStrategy`
    public init(eventLoopGroup: EventLoopGroup,
                initialBucketCapacity: Int = 500,
                maxRetries: Int = 10,
                backOffScaleFactor: TimeInterval = 0.025,
                jitterMode: ExponentialBackoffJitterMode = .default,
                generateRandom: (() -> UInt64)? = nil,
                shutdownCallback: ShutdownCallback? = nil,
                allocator: Allocator = defaultAllocator) throws {

        var exponentialBackoffRetryOptions = aws_exponential_backoff_retry_options()
        exponentialBackoffRetryOptions.el_group = eventLoopGroup.rawValue
        exponentialBackoffRetryOptions.max_retries = maxRetries
        exponentialBackoffRetryOptions.backoff_scale_factor_ms = UInt32(backOffScaleFactor.millisecond)
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
    /// - Returns: `RetryToken`
    public func acquireToken(partitionId: String?) async throws -> RetryToken {
        return try await withCheckedThrowingContinuation { continuation in

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

    public func scheduleRetry(token: RetryToken, errorType: RetryError) async throws -> RetryToken {
        try await withCheckedThrowingContinuation { continuation in
            let continuationCore = ContinuationCore(continuation: continuation)
            if aws_retry_strategy_schedule_retry(token.rawValue,
                                                 errorType.rawValue,
                                                 onRetryReady,
                                                 continuationCore.passRetained()) != AWS_OP_SUCCESS {
                continuationCore.release()
                continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
            }
        }
    }

    /// Records a successful retry.You should always call it after a successful operation
    /// or your system will never recover during an outage.
    public func recordSuccess(token: RetryToken) {
        aws_retry_token_record_success(token.rawValue)
    }

    deinit {
        aws_retry_strategy_release(rawValue)
    }
}

private func onRetryReady(token: UnsafeMutablePointer<aws_retry_token>?,
                          errorCode: Int32,
                          userData: UnsafeMutableRawPointer!) {
    let crtRetryStrategyCore = Unmanaged<ContinuationCore<RetryToken>>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        crtRetryStrategyCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    aws_retry_token_acquire(token!)
    crtRetryStrategyCore.continuation.resume(returning: RetryToken(rawValue: token!))
}

private func onRetryTokenAcquired(retry_strategy: UnsafeMutablePointer<aws_retry_strategy>?,
                                  errorCode: Int32,
                                  token: UnsafeMutablePointer<aws_retry_token>?,
                                  userData: UnsafeMutableRawPointer!) {
    let crtRetryStrategyCore = Unmanaged<ContinuationCore<RetryToken>>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        crtRetryStrategyCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    crtRetryStrategyCore.continuation.resume(returning: RetryToken(rawValue: token!))
}
