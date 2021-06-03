//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public final class CRTAWSRetryStrategy {
    let allocator: Allocator

    var rawValue: UnsafeMutablePointer<aws_retry_strategy>
    
    init(retryStrategy: UnsafeMutablePointer<aws_retry_strategy>,
         allocator: Allocator) {
        self.rawValue = retryStrategy
        self.allocator = allocator
    }
    
    public convenience init(fromProvider impl: CRTRetryStrategy,
                            allocator: Allocator = defaultAllocator) {
        let wrapped = WrappedCRTRetryStrategy(impl: impl, allocator: allocator)
        self.init(retryStrategy: &wrapped.rawValue, allocator: wrapped.allocator)
    }
}
