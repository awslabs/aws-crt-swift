//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

public struct CRTIMDSClientOptions {
    public let bootstrap: ClientBootstrap
    
    public let retryStrategy: CRTAWSRetryStrategy
    
    public let protocolVersion: CRTIMDSProtocolVersion
    
    public let shutDownOptions: CRTIDMSClientShutdownOptions
}
