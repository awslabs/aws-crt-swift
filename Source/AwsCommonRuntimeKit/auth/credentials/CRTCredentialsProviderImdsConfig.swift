//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

public protocol CRTCredentialsProviderImdsConfig {
    var bootstrap: ClientBootstrap { get }
    var shutdownCallback: ShutdownCallback? { get }
    var imdsVersion: aws_imds_protocol_version { get }
}
