//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
public typealias CredentialsContinuation = CheckedContinuation<Result<CRTCredentials, CRTError>, Never>
public struct CRTCredentialsProviderCallbackData {
    public var onCredentialsResolved: CredentialsContinuation?
    public let allocator: Allocator

    public init(allocator: Allocator = defaultAllocator,
                onCredentialsResolved: CredentialsContinuation? = nil) {
        self.onCredentialsResolved = onCredentialsResolved
        self.allocator = allocator
    }
}
