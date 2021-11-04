//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
public typealias IAMProfileContinuation = CheckedContinuation<CRTIAMProfile?, Error>
public struct CRTIMDSClientIAMProfileCallbackData {
    public var continuation: IAMProfileContinuation?
    public let allocator: Allocator

    public init(allocator: Allocator = defaultAllocator,
                continuation: IAMProfileContinuation?) {
        self.allocator = allocator
        self.continuation = continuation
    }
}
