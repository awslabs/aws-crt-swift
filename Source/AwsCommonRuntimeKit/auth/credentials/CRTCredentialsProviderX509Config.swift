//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
#if os(macOS)

public protocol CRTCredentialsProviderX509Config {
    var shutDownOptions: ShutDownCallbackOptions? {get set}
    var bootstrap: ClientBootstrap {get set}
    var tlsConnectionOptions: TlsConnectionOptions { get set}
    var thingName: String { get set}
    var roleAlias: String { get set}
    var endpoint: String { get set}
    var proxyOptions: HttpProxyOptions? {get set}
}

#endif
