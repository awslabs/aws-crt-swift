//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
public typealias ResourceContinuation = CheckedContinuation<String?, Error>
public struct CRTIMDSClientResourceCallbackData {
    public var continuation: ResourceContinuation?
    public let allocator: Allocator

    public init(allocator: Allocator = defaultAllocator, continuation: ResourceContinuation?) {
        self.allocator = allocator
        self.continuation = continuation
    }
}
