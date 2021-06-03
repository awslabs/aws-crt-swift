//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public final class CRTAWSRetryToken {
    var rawValue: UnsafeMutablePointer<aws_retry_token>
    
    public init(retryStrategy: CRTRetryStrategy, allocator: Allocator = defaultAllocator) {
        let intPointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        intPointer.pointee = 1
        let atomicVar = aws_atomic_var(value: UnsafeMutableRawPointer(intPointer))
        let retryStrategyPtr = UnsafeMutablePointer<CRTRetryStrategy>.allocate(capacity: 1)
        retryStrategyPtr.initialize(to: retryStrategy)
        let retryToken = aws_retry_token(allocator: allocator.rawValue,
                                        retry_strategy: retryStrategy.rawValue,
                                        ref_count: atomicVar,
                                        impl: retryStrategyPtr)
        let retryTokenPtr = UnsafeMutablePointer<aws_retry_token>.allocate(capacity: 1)
        retryTokenPtr.initialize(to: retryToken)
        self.rawValue = retryTokenPtr
    }
    
    public init(rawValue: UnsafeMutablePointer<aws_retry_token>,
                allocator: Allocator = defaultAllocator) {
        self.rawValue = rawValue
    }
}
