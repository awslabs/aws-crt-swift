//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public final class CRTAWSRetryToken {
    var rawValue: UnsafeMutablePointer<aws_retry_token>

    public init(retryStrategy: CRTRetryStrategy, allocator: Allocator = defaultAllocator) {
        let atomicVar = Atomic<Int>(1)
        let retryStrategyPtr: UnsafeMutablePointer<CRTRetryStrategy> = fromPointer(ptr: retryStrategy)
        let retryToken = aws_retry_token(allocator: allocator.rawValue,
                                         retry_strategy: retryStrategy.rawValue,
                                         ref_count: atomicVar.rawValue,
                                         impl: retryStrategyPtr)
        self.rawValue = fromPointer(ptr: retryToken)
    }

    public init(rawValue: UnsafeMutablePointer<aws_retry_token>,
                allocator: Allocator = defaultAllocator) {
        self.rawValue = rawValue
    }

    deinit {
        aws_retry_token_release(rawValue)
    }
}
