//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

struct AWSCredentialsProviderImdsConfig {
    public let bootstrap: ClientBootstrap
    public let shutdownOptions: AWSCredentialsProviderShutdownOptions

    public init(bootstrap: ClientBootstrap,
                shutdownOptions: AWSCredentialsProviderShutdownOptions) {
        self.bootstrap = bootstrap
        self.shutdownOptions = shutdownOptions
    }
}
