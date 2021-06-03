//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo

public struct CRTRetryerCallbackData {
    public typealias OnTokenAcquired = (CRTAWSRetryToken?, CRTError) -> Void
    public var onTokenAcquired: OnTokenAcquired?
    public let allocator: Allocator

    public init(allocator: Allocator = defaultAllocator,
                onTokenAcquired: OnTokenAcquired? = nil) {
        self.onTokenAcquired = onTokenAcquired
        self.allocator = allocator
    }
}
