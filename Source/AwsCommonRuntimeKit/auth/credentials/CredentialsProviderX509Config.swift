//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
#if os(macOS)
public struct CredentialsProviderX509Config {

    public let shutDownOptions: CredentialsProviderShutdownOptions?
    public let bootstrap: ClientBootstrap
    public let tlsConnectionOptions: TlsConnectionOptions
    public let thingName: String
    public let roleAlias: String
    public let endpoint: String
    public let proxyOptions: HttpProxyOptions?

    public init(bootstrap: ClientBootstrap,
                tlsConnectionOptions: TlsConnectionOptions,
                thingName: String,
                roleAlias: String,
                endpoint: String,
                proxyOptions: HttpProxyOptions? = nil,
                shutDownOptions: CredentialsProviderShutdownOptions? = nil) {
        self.bootstrap = bootstrap
        self.tlsConnectionOptions = tlsConnectionOptions
        self.thingName = thingName
        self.roleAlias = roleAlias
        self.endpoint = endpoint
        self.proxyOptions = proxyOptions
        self.shutDownOptions = shutDownOptions
    }
}
#endif
