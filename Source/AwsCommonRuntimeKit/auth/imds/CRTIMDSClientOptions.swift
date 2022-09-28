//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct CRTIMDSClientOptions {
    public let bootstrap: ClientBootstrap
    public let retryStrategy: CRTAWSRetryStrategy
    public let protocolVersion: CRTIMDSProtocolVersion
    public let shutDownOptions: CRTIDMSClientShutdownOptions?

    public init(bootstrap: ClientBootstrap,
                retryStrategy: CRTAWSRetryStrategy,
                protocolVersion: CRTIMDSProtocolVersion = .version2,
                shutDownOptions: CRTIDMSClientShutdownOptions? = nil) {
        self.bootstrap = bootstrap
        self.retryStrategy = retryStrategy
        self.protocolVersion = protocolVersion
        self.shutDownOptions = shutDownOptions
    }
}
