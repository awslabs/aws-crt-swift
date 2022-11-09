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

    deinit {
        aws_retry_strategy_release(rawValue)
    }
}
