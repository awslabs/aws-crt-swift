//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

public struct CredentialsProviderImdsConfig {
    public let bootstrap: ClientBootstrap
    public let shutdownOptions: CredentialsProviderShutdownOptions?
    public let imdsVersion: aws_imds_protocol_version

    public init(bootstrap: ClientBootstrap,
                imdsVersion: aws_imds_protocol_version = IMDS_PROTOCOL_V2,
                shutdownOptions: CredentialsProviderShutdownOptions? = nil) {
        self.bootstrap = bootstrap
        self.imdsVersion = imdsVersion
        self.shutdownOptions = shutdownOptions
    }
}
