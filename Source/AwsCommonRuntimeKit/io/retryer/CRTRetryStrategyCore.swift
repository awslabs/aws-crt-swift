//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

typealias RetryStrategyAcquireTokenContinuation = CheckedContinuation<CRTAWSRetryToken, Error>
typealias RetryStrategyScheduleRetryContinuation = CheckedContinuation<(), Error>

class CRTRetryStrategyCore<T> {
    var continuation: CheckedContinuation<T, Error>

    init(continuation: CheckedContinuation<T, Error>) {
        self.continuation = continuation
    }

    private func getRetainedSelf() -> UnsafeMutableRawPointer {
        return Unmanaged<CRTRetryStrategyCore>.passRetained(self).toOpaque()
    }

    func retainedAcquireTokenFromCRT(timeout: UInt64, partitionId: String, crtAWSRetryStrategy: CRTAWSRetryStrategy) {
        let retainedSelf = getRetainedSelf()
        if (partitionId.withByteCursorPointer { partitionIdCursorPointer in
            aws_retry_strategy_acquire_retry_token(crtAWSRetryStrategy.rawValue,
                                                   partitionIdCursorPointer,
                                                   onRetryTokenAcquired,
                                                   retainedSelf,
                                                   timeout)
        }) != AWS_OP_SUCCESS {
            release()
            continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
        }
    }

    func retainedScheduleRetryToCRT(token: CRTAWSRetryToken, errorType: CRTRetryError) {
        let retainedSelf = getRetainedSelf()
        if aws_retry_strategy_schedule_retry(token.rawValue,
                errorType.rawValue,
                onRetryReady,
                retainedSelf) != AWS_OP_SUCCESS {
            release()
            continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
        }
    }

    private func release() {
        Unmanaged.passUnretained(self).release()
    }
}

private func onRetryTokenAcquired(retry_strategy: UnsafeMutablePointer<aws_retry_strategy>?,
                                  errorCode: Int32,
                                  token: UnsafeMutablePointer<aws_retry_token>?,
                                  userData: UnsafeMutableRawPointer!) {
    let crtRetryStrategyCore = Unmanaged<CRTRetryStrategyCore<CRTAWSRetryToken>>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        crtRetryStrategyCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    crtRetryStrategyCore.continuation.resume(returning: CRTAWSRetryToken(rawValue: token!))
}

private func onRetryReady(token: UnsafeMutablePointer<aws_retry_token>?,
                          errorCode: Int32,
                          userData: UnsafeMutableRawPointer!) {
    let crtRetryStrategyCore = Unmanaged<CRTRetryStrategyCore<()>>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        crtRetryStrategyCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    crtRetryStrategyCore.continuation.resume()
}
