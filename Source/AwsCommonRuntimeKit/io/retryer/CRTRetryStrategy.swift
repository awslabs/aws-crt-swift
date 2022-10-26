//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public protocol CRTRetryStrategy {
    var allocator: Allocator {get set}
    var rawValue: UnsafeMutablePointer<aws_retry_strategy> {get set}
    func acquireRetryToken(partitionId: String) async throws -> CRTAWSRetryToken
    func scheduleRetry(token: CRTAWSRetryToken,
                       errorType: CRTRetryError) async throws -> CRTAWSRetryToken
    func recordSuccess(token: CRTAWSRetryToken)
    func releaseToken(token: CRTAWSRetryToken)
}

private func acquireRetryToken(_ retryStrategy: UnsafeMutablePointer<aws_retry_strategy>?,
                               _ partitionId: UnsafePointer<aws_byte_cursor>?,
                               _ callbackFn: (@convention(c)(UnsafeMutablePointer<aws_retry_strategy>?,
                                                             Int32,
                                                             UnsafeMutablePointer<aws_retry_token>?,
                                                             UnsafeMutableRawPointer?) -> Void)?,
                               userData: UnsafeMutableRawPointer?, wtf: UInt64) -> Int32 {

    guard let retryStrategySwift = userData?.assumingMemoryBound(to: CRTRetryStrategy.self) else {
        return 1
    }

    let tokenCallbackData = CRTAcquireTokenCallbackData(allocator: retryStrategySwift.pointee.allocator)
    let callbackPointer = UnsafeMutablePointer<CRTAcquireTokenCallbackData>.allocate(capacity: 1)
    callbackPointer.initialize(to: tokenCallbackData)
    Task {
        do {
            let result = try await retryStrategySwift.pointee.acquireRetryToken(partitionId: partitionId?.pointee.toString() ?? "")
            callbackFn?(retryStrategy, 0, result.rawValue, callbackPointer)
        } catch let crtError as CRTError {
                callbackFn?(retryStrategy, crtError.code, nil, callbackPointer)
        } catch {} // TODO: handle other errors
    }

    return 0
}

private func scheduleRetry(_ token: UnsafeMutablePointer<aws_retry_token>?,
                           _ errorType: aws_retry_error_type,
                           _ callbackFn: (@convention(c) (UnsafeMutablePointer<aws_retry_token>?,
                                                          Int32,
                                                          UnsafeMutableRawPointer?) -> Void)?,
                           userData: UnsafeMutableRawPointer?) -> Int32 {

    guard let retryStrategy = userData?.assumingMemoryBound(to: CRTRetryStrategy.self),
          let token = token else {
        return 1
    }

    let scheduleCallbackData = CRTScheduleRetryCallbackData(allocator: retryStrategy.pointee.allocator)
    let callbackPointer = UnsafeMutablePointer<CRTScheduleRetryCallbackData>.allocate(capacity: 1)
    callbackPointer.initialize(to: scheduleCallbackData)
    Task {
        do {
            _ = try await retryStrategy.pointee.scheduleRetry(token: CRTAWSRetryToken(rawValue: token),
                                                                            errorType: CRTRetryError(rawValue: errorType))
            callbackFn?(token, 0, callbackPointer)
        } catch let crtError as CRTError {
            callbackFn?(token, crtError.code, callbackPointer)
        } catch {} // TODO: handle other errors
    }

    return 0
}

private func destroy(_ retryPtr: UnsafeMutablePointer<aws_retry_strategy>?) {
    guard let retryStrategyPtr = retryPtr else {
        return
    }

    aws_retry_strategy_release(retryStrategyPtr)
}

private func recordSuccess(_ retryToken: UnsafeMutablePointer<aws_retry_token>?) -> Int32 {
    guard let retryToken = retryToken else {
        return 1
    }

    return aws_retry_token_record_success(retryToken)
}

private func releaseToken(_ retryToken: UnsafeMutablePointer<aws_retry_token>?) {
    guard let retryToken = retryToken else {
        return
    }

    aws_retry_token_release(retryToken)
}

class WrappedCRTRetryStrategy {
    var rawValue: aws_retry_strategy
    let allocator: Allocator
    private let implementationPtr: UnsafeMutablePointer<CRTRetryStrategy>
    private let vTablePtr: UnsafeMutablePointer<aws_retry_strategy_vtable>

    init(impl: CRTRetryStrategy,
         allocator: Allocator) {
        let vtable = aws_retry_strategy_vtable(destroy: destroy,
                                               acquire_token: acquireRetryToken,
                                               schedule_retry: scheduleRetry,
                                               record_success: recordSuccess,
                                               release_token: releaseToken)

        let intPointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        intPointer.pointee = 1
        let atomicVar = aws_atomic_var(value: UnsafeMutableRawPointer(intPointer))
        self.allocator = allocator
        let retryStategyPtr = UnsafeMutablePointer<CRTRetryStrategy>.allocate(capacity: 1)
        retryStategyPtr.initialize(to: impl)
        let vTablePtr = UnsafeMutablePointer<aws_retry_strategy_vtable>.allocate(capacity: 1)
        vTablePtr.initialize(to: vtable)
        self.vTablePtr = vTablePtr
        self.implementationPtr = retryStategyPtr
        self.rawValue = aws_retry_strategy(allocator: allocator.rawValue,
                                           vtable: vTablePtr,
                                           ref_count: atomicVar,
                                           impl: retryStategyPtr)
    }

}
