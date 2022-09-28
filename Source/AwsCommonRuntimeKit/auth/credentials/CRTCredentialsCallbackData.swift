//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
public typealias CredentialsContinuation = CheckedContinuation<CRTCredentials, Error>
public struct CRTCredentialsProviderCallbackData {
    public var continuation: CredentialsContinuation?
    public let allocator: Allocator

    public init(allocator: Allocator = defaultAllocator,
                continuation: CredentialsContinuation? = nil) {
        self.allocator = allocator
        self.continuation = continuation
    }
}
