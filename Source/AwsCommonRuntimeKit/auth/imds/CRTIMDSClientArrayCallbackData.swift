//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public struct CRTIMDSClientArrayCallbackData {
    public typealias OnArrayResolved = ([String]?, CRTError) -> Void
    public var onArrayResolved: OnArrayResolved
    public let allocator: Allocator

    public init(allocator: Allocator = defaultAllocator,
                onArrayResolved: @escaping OnArrayResolved) {
        self.onArrayResolved = onArrayResolved
        self.allocator = allocator
    }
}
