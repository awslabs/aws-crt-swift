//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public struct CRTIMDSClientResourceCallbackData {
    public typealias OnResourceResolved = (String?, CRTError) -> Void
    public var onResourceResolved: OnResourceResolved
    public let allocator: Allocator

    public init(allocator: Allocator = defaultAllocator,
                onResourceResolved: @escaping OnResourceResolved) {
        self.onResourceResolved = onResourceResolved
        self.allocator = allocator
    }
}
