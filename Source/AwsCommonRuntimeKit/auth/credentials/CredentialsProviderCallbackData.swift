//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

class CredentialProviderCallbackData {
    public typealias OnCredentialsResolved = (Credentials?, Int32) -> Void
    public let onCredentialsResolved: OnCredentialsResolved
    public let provider: CredentialsProvider?
    public let allocator: Allocator

    public init(provider: CredentialsProvider,
                allocator: Allocator,
                onCredentialsResolved: @escaping OnCredentialsResolved) {
        self.provider = provider
        self.onCredentialsResolved = onCredentialsResolved
        self.allocator = allocator
    }
}
