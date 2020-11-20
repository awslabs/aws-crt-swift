//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public struct CredentialsProviderCachedConfig {
    public let shutDownOptions: CredentialsProviderShutdownOptions?
    public var source: CRTAWSCredentialsProvider
    public let refreshTimeMs: Int64

    public init(source: CRTAWSCredentialsProvider,
                refreshTimeMs: Int64,
                shutDownOptions: CredentialsProviderShutdownOptions? = nil) {
        self.source = source
        self.refreshTimeMs = refreshTimeMs
        self.shutDownOptions = shutDownOptions
    }
}
