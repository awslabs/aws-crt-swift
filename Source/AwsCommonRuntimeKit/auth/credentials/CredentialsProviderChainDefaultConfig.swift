//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

struct CredentialsProviderChainDefaultConfig {
    public let shutDownOptions: CredentialsProviderShutdownOptions?
    public let bootstrap: ClientBootstrap
    
    public init(bootstrap: ClientBootstrap,
                shutDownOptions: CredentialsProviderShutdownOptions? = nil) {
        self.bootstrap = bootstrap
        self.shutDownOptions = shutDownOptions
    }
}
