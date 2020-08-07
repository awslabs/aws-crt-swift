//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

struct CredentialsProviderCachedConfig {
    public let shutDownOptions: CredentialsProviderShutdownOptions?
    public let source: CredentialsProvider
    public let refreshTimeMs: Int64

    public init(source: CredentialsProvider,
                refreshTimeMs: Int64,
                shutDownOptions: CredentialsProviderShutdownOptions? = nil) {
        self.source = source
        self.refreshTimeMs = refreshTimeMs
        self.shutDownOptions = shutDownOptions
    }
}
