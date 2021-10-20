//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public struct CRTIMDSClientIAMProfileCallbackData {
    public typealias OnIAMProfileResolved = (CRTIAMProfile?, CRTError) -> Void
    public var onIAMProfileResolved: OnIAMProfileResolved
    public let allocator: Allocator

    public init(allocator: Allocator = defaultAllocator,
                onIAMProfileResolved: @escaping OnIAMProfileResolved) {
        self.onIAMProfileResolved = onIAMProfileResolved
        self.allocator = allocator
    }
}
