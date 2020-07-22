//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

struct AWSCredentialsProviderImdsConfig {
    public let bootstrap: ClientBootstrap
    public let shutdownOptions: AWSCredentialsProviderShutdownOptions
    public let imdsVersion: aws_imds_protocol_version

    public init(bootstrap: ClientBootstrap,
                shutdownOptions: AWSCredentialsProviderShutdownOptions,
                imdsVersion: aws_imds_protocol_version = IMDS_PROTOCOL_V2) {
        self.bootstrap = bootstrap
        self.shutdownOptions = shutdownOptions
        self.imdsVersion = imdsVersion
    }
}
