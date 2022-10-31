//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

typealias CRTRetryStrategyContinuation = CheckedContinuation<CRTAWSRetryToken, Error>

class CRTRetryStrategyCore {
    var continuation: CRTRetryStrategyContinuation

    init(continuation: CRTRetryStrategyContinuation) {
        self.continuation = continuation
    }

    private func getRetainedSelf() -> UnsafeMutableRawPointer {
        return Unmanaged<CRTRetryStrategyCore>.passRetained(self).toOpaque()
    }

    func retainedScheduleRetryToCRT(token: CRTAWSRetryToken, errorType: CRTRetryError) {
        //TODO: callback is called if an error occurred?
        if aws_retry_strategy_schedule_retry(token.rawValue,
                                             errorType.rawValue,
                                             onRetryReady,
                                             getRetainedSelf()) != AWS_OP_SUCCESS {
            //TODO: Do we need to call token_release here?
            release()
            continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
        }
    }

    func retainedAcquireTokenFromCRT(timeout: UInt64, partitionId: String, crtAWSRetryStrategy: CRTAWSRetryStrategy) {
        if (partitionId.withByteCursorPointer { partitionIdCursorPointer in
            aws_retry_strategy_acquire_retry_token(crtAWSRetryStrategy.rawValue,
                                                   partitionIdCursorPointer,
                                                   onRetryTokenAcquired,
                                                   getRetainedSelf(),
                                                   timeout)
        }) != AWS_OP_SUCCESS {
            release()
            continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
        }
    }

    private func release() {
        Unmanaged.passUnretained(self).release()
    }
}

func onRetryReady(token: UnsafeMutablePointer<aws_retry_token>?,
                  errorCode: Int32,
                  userData: UnsafeMutableRawPointer!) {
    let crtRetryStrategyCore = Unmanaged<CRTRetryStrategyCore>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        crtRetryStrategyCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }
    guard let token = token else {
        crtRetryStrategyCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }
    crtRetryStrategyCore.continuation.resume(returning: CRTAWSRetryToken(rawValue: token))
}

func onRetryTokenAcquired(retry_strategy: UnsafeMutablePointer<aws_retry_strategy>?,
                          errorCode: Int32,
                          token: UnsafeMutablePointer<aws_retry_token>?,
                          userData: UnsafeMutableRawPointer!) {
    let crtRetryStrategyCore = Unmanaged<CRTRetryStrategyCore>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        crtRetryStrategyCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    crtRetryStrategyCore.continuation.resume(returning: CRTAWSRetryToken(rawValue: token!))
}
