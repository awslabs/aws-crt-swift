//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo

public struct CRTScheduleRetryCallbackData {
    public typealias OnRetryReady = (CRTAWSRetryToken?, CRTError) -> Void
    public var onRetryReady: OnRetryReady?
    public let allocator: Allocator

    public init(allocator: Allocator = defaultAllocator,
                onRetryReady: OnRetryReady? = nil) {
        self.onRetryReady = onRetryReady
        self.allocator = allocator
    }
}
