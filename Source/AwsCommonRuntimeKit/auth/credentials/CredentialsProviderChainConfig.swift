//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

struct CredentialsProviderChainConfig {
	public let shutDownOptions: CredentialsProviderShutdownOptions?
	public let providers: [CredentialsProvider]
    
    public init(providers: [CredentialsProvider],
                shutDownOptions: CredentialsProviderShutdownOptions? = nil) {
        self.providers = providers
        self.shutDownOptions = shutDownOptions
    }
}
