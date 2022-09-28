//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCAuth

public protocol CRTCredentialsProviderImdsConfig {
    var bootstrap: ClientBootstrap { get set }
    var shutdownOptions: CRTCredentialsProviderShutdownOptions? { get set }
    var imdsVersion: aws_imds_protocol_version { get set }
}
