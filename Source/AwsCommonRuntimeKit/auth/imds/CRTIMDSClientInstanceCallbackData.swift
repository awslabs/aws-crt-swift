//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
public typealias InstanceInfoContinuation = CheckedContinuation<CRTIMDSInstanceInfo?, Error>
public struct CRTIMDSClientInstanceCallbackData {
    public var continuation: InstanceInfoContinuation?
    public let allocator: Allocator

    public init(allocator: Allocator = defaultAllocator,
                continuation: InstanceInfoContinuation?)
    {
        self.allocator = allocator
        self.continuation = continuation
    }
}
