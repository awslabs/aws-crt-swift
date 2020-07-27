//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

struct CredentialsProviderChainDefaultConfig {
    public let shutDownOptions: CredentialsProviderShutdownOptions
    public let bootstrap: ClientBootstrap
    
    public init(shutDownOptions: CredentialsProviderShutdownOptions,
                bootstrap: ClientBootstrap) {
        self.shutDownOptions = shutDownOptions
        self.bootstrap = bootstrap
    }
}
