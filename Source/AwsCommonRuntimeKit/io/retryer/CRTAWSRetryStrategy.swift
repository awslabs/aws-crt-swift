//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

//TODO: rename class to RetryStrategy or CRTRetryStrategy. We have inconsistent CRT/AWS as a prefix of some classes.
// I am not renaming it for now because it messes up the git change log. Will create a separate PR for just renaming.
public class CRTAWSRetryStrategy {
    let allocator: Allocator
    let rawValue: UnsafeMutablePointer<aws_retry_strategy>

    /// Creates an AWS Retryer implementing the correct retry strategy.
    ///
    /// - Parameters:
    ///   - crtStandardRetryOptions:  The `CRTStandardRetryOptions` options object.
    /// - Returns: `CRTAWSRetryStrategy`
    public init(crtStandardRetryOptions: CRTStandardRetryOptions, allocator: Allocator = defaultAllocator) throws {
        self.allocator = allocator
        guard let rawValue = (crtStandardRetryOptions.withCPointer { retryOptionsPointer in
            return aws_retry_strategy_new_standard(allocator.rawValue, retryOptionsPointer)
        }) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    public func acquireToken(timeout: UInt64 = 0, partitionId: String) async throws -> CRTAWSRetryToken {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CRTAWSRetryToken, Error>) in
            let continuationCore = ContinuationCore(continuation: continuation)
            let retainedContinuation = continuationCore.passRetained()
            if (partitionId.withByteCursorPointer { partitionIdCursorPointer in
                aws_retry_strategy_acquire_retry_token(rawValue,
                        partitionIdCursorPointer,
                        onRetryTokenAcquired,
                        retainedContinuation,
                        timeout)
            }) != AWS_OP_SUCCESS {
                continuationCore.release()
                continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
            }
        }
    }

    public func scheduleRetry(token: CRTAWSRetryToken, errorType: CRTRetryError) async throws {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<(), Error>) in
            let continuationCore = ContinuationCore(continuation: continuation)
            let retainedContinuation = continuationCore.passRetained()
            if aws_retry_strategy_schedule_retry(token.rawValue,
                    errorType.rawValue,
                    onRetryReady,
                    retainedContinuation) != AWS_OP_SUCCESS {
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
