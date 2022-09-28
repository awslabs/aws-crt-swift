//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo

public typealias TokenContinuation = CheckedContinuation<CRTAWSRetryToken, Error>
public struct CRTAcquireTokenCallbackData {
    public var continuation: TokenContinuation?
    public let allocator: Allocator

    public init(allocator: Allocator = defaultAllocator,
                continuation: TokenContinuation? = nil) {
        self.continuation = continuation
        self.allocator = allocator
    }
}
