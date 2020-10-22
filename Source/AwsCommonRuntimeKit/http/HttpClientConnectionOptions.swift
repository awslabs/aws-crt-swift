//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public struct HttpClientConnectionOptions {

    
    public let clientBootstrap: ClientBootstrap
    public let hostName: String
    public let initialWindowSize: Int
    public let port: UInt16
    public let proxyOptions: HttpProxyOptions?
    public var socketOptions: SocketOptions
    public let tlsOptions: TlsConnectionOptions?
    /**
     If set to true, then the TCP read back pressure mechanism will be enabled. You should
     only use this if you're allowing http response body data to escape the callbacks. E.g. you're
     putting the data into a queue for another thread to process and need to make sure the memory
     usage is bounded (e.g. reactive streams).
     If this is enabled, you must call HttpStream.updateWindow() for every
     byte read from the OnIncomingBody callback.
     Will true if manual window management is used, but defaults to false
     */
    public let enableManualWindowManagement: Bool
    
    public init(clientBootstrap bootstrap: ClientBootstrap,
                hostName: String,
                initialWindowSize: Int = Int.max,
                port: UInt16,
                proxyOptions: HttpProxyOptions?,
                socketOptions: SocketOptions,
                tlsOptions: TlsConnectionOptions?,
                enableManualWindowManagement: Bool = false) {

        self.clientBootstrap = bootstrap
        self.hostName = hostName
        self.initialWindowSize = initialWindowSize
        self.port = port
        self.proxyOptions = proxyOptions
        self.socketOptions = socketOptions
        self.tlsOptions = tlsOptions
        self.enableManualWindowManagement = enableManualWindowManagement
    }
}
