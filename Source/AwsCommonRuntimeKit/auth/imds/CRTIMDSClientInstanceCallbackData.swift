//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public struct CRTIMDSClientInstanceCallbackData {
    public typealias OnInstanceInfoResolved = (CRTIMDSInstanceInfo?, CRTError) -> Void
    public var onInstanceInfoResolved: OnInstanceInfoResolved
    public let allocator: Allocator

    public init(allocator: Allocator = defaultAllocator,
                onInstanceInfoResolved: @escaping OnInstanceInfoResolved) {
        self.onInstanceInfoResolved = onInstanceInfoResolved
        self.allocator = allocator
    }
}
