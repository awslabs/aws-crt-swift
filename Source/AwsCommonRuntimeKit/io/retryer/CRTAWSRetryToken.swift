//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public final class CRTAWSRetryToken {
    var rawValue: UnsafeMutablePointer<aws_retry_token>

    public init(retryStrategy: CRTRetryStrategy, allocator: Allocator = defaultAllocator) {
        let intPointer: UnsafeMutableRawPointer = fromPointer(ptr: 1)
        let atomicVar = aws_atomic_var(value: intPointer)
        let retryStrategyPtr: UnsafeMutablePointer<CRTRetryStrategy> = fromPointer(ptr: retryStrategy)
        let retryToken = aws_retry_token(allocator: allocator.rawValue,
                                        retry_strategy: retryStrategy.rawValue,
                                        ref_count: atomicVar,
                                        impl: retryStrategyPtr)
        let retryTokenPtr: UnsafeMutablePointer<aws_retry_token> = fromPointer(ptr: retryToken)
        self.rawValue = retryTokenPtr
    }

    public init(rawValue: UnsafeMutablePointer<aws_retry_token>,
                allocator: Allocator = defaultAllocator) {
        self.rawValue = rawValue
    }

    deinit {
        aws_retry_token_release(rawValue)
    }
}
