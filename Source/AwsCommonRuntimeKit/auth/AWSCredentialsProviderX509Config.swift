//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

struct AWSCredentialsProviderX509Config {
    
    public let shutDownOptions: AWSCredentialsProviderShutdownOptions
    public let bootstrap: ClientBootstrap
    public let tlsConnectionOptions: TlsConnectionOptions
    public let thingName: String
    public let roleAlias: String
    public let endpoint: String
    public let proxyOptions: HttpClientConnectionProxyOptions
    
    public init(shutDownOptions: AWSCredentialsProviderShutdownOptions,
                bootstrap: ClientBootstrap,
                tlsConnectionOptions: TlsConnectionOptions,
                thingName: String,
                roleAlias: String,
                endpoint: String,
                proxyOptions: HttpClientConnectionProxyOptions) {
        self.shutDownOptions = shutDownOptions
        self.bootstrap = bootstrap
        self.tlsConnectionOptions = tlsConnectionOptions
        self.thingName = thingName
        self.roleAlias = roleAlias
        self.endpoint = endpoint
        self.proxyOptions = proxyOptions
    }

}
