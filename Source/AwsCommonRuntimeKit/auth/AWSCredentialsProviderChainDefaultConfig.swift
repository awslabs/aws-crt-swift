//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

struct AWSCredentialsProviderChainDefaultConfig {
    public let shutDownOptions: AWSCredentialsProviderShutdownOptions
    public let bootstrap: ClientBootstrap
    
    public init(shutDownOptions: AWSCredentialsProviderShutdownOptions,
                bootstrap: ClientBootstrap) {
        self.shutDownOptions = shutDownOptions
        self.bootstrap = bootstrap
    }

}
