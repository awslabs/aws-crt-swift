//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

struct CredentialsProviderImdsConfig {
    public let bootstrap: ClientBootstrap
    public let shutdownOptions: CredentialsProviderShutdownOptions
    public let imdsVersion: aws_imds_protocol_version

    public init(bootstrap: ClientBootstrap,
                shutdownOptions: CredentialsProviderShutdownOptions,
                imdsVersion: aws_imds_protocol_version = IMDS_PROTOCOL_V2) {
        self.bootstrap = bootstrap
        self.shutdownOptions = shutdownOptions
        self.imdsVersion = imdsVersion
    }
}
