//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

public struct HttpClientConnectionOptions {
    public typealias OnConnectionSetup =  (HttpClientConnection?, Int32) -> Void
    public typealias OnConnectionShutdown = (HttpClientConnection, Int32) -> Void

    public let clientBootstrap: ClientBootstrap
    public let hostName: String
    public let initialWindowSize: Int
    public let port: UInt16
    public let proxyOptions: HttpClientConnectionProxyOptions?
    public var socketOptions: SocketOptions
    public let tlsOptions: TlsConnectionOptions?

    public let onConnectionSetup: OnConnectionSetup
    public let onConnectionShutdown: OnConnectionSetup

    public init(clientBootstrap bootstrap: ClientBootstrap,
                hostName: String,
                initialWindowSize: Int = Int.max,
                port: UInt16,
                proxyOptions: HttpClientConnectionProxyOptions?,
                socketOptions: SocketOptions,
                tlsOptions: TlsConnectionOptions?,
                onConnectionSetup: @escaping OnConnectionSetup,
                onConnectionShutdown: @escaping OnConnectionSetup) {
        self.clientBootstrap = bootstrap
        self.hostName = hostName
        self.initialWindowSize = initialWindowSize
        self.port = port
        self.proxyOptions = proxyOptions
        self.socketOptions = socketOptions
        self.tlsOptions = tlsOptions
        self.onConnectionSetup = onConnectionSetup
        self.onConnectionShutdown = onConnectionShutdown
    }
}
