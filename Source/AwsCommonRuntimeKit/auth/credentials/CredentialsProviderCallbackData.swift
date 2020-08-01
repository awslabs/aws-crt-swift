//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

struct CredentialProviderCallbackData {
    public typealias OnCredentialsResolved = (Credentials?, Int32) -> Void
    public let onCredentialsResolved: OnCredentialsResolved
    public let allocator: Allocator

    public init(allocator: Allocator,
                onCredentialsResolved: @escaping OnCredentialsResolved) {
        self.onCredentialsResolved = onCredentialsResolved
        self.allocator = allocator
    }
}
