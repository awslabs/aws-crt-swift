//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

struct CredentialProviderCallbackData {
    public typealias OnCredentialsResolved = (Credentials, Int32) -> Void
    public let onCredentialsResolved: OnCredentialsResolved
    public let provider: CredentialsProvider?

    public init(provider: CredentialsProvider, onCredentialsResolved: @escaping OnCredentialsResolved) {
        self.provider = provider
        self.onCredentialsResolved = onCredentialsResolved
    }
}
