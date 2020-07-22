//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

struct AWSCredentialsProviderChainConfig {
	public let shutDownOptions: AWSCredentialsProviderShutdownOptions
	public let providers: [CredentialsProvider]
    
    public init(shutDownOptions: AWSCredentialsProviderShutdownOptions,
                providers: [CredentialsProvider]) {
        self.shutDownOptions = shutDownOptions
        self.providers = providers
    }
}
