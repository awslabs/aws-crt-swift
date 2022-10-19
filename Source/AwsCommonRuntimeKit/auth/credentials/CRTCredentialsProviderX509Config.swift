//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
#if os(macOS)

public protocol CRTCredentialsProviderX509Config {
    var shutDownOptions: ShutDownCallbackOptions? { get }
    var bootstrap: ClientBootstrap { get }
    var tlsConnectionOptions: TlsConnectionOptions { get }
    var thingName: String { get }
    var roleAlias: String { get }
    var endpoint: String { get }
    var proxyOptions: HttpProxyOptions? { get }
}

#endif
