//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
public typealias ArrayContinuation = CheckedContinuation<[String]?, Error>
public struct CRTIMDSClientArrayCallbackData {
    public var continuation: ArrayContinuation?
    public let allocator: Allocator

    public init(allocator: Allocator = defaultAllocator,
                continuation: ArrayContinuation?)
    {
        self.allocator = allocator
        self.continuation = continuation
    }
}
