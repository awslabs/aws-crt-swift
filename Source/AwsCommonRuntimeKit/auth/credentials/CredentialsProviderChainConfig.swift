//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

struct CredentialsProviderChainConfig {
	public let shutDownOptions: CredentialsProviderShutdownOptions
	public let providers: [CredentialsProvider]
    
    public init(shutDownOptions: CredentialsProviderShutdownOptions,
                providers: [CredentialsProvider]) {
        self.shutDownOptions = shutDownOptions
        self.providers = providers
    }
}
