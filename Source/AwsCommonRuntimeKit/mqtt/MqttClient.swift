//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCMqtt

// swiftlint:disable function_parameter_count
public final class MqttClient {
    let rawValue: UnsafeMutablePointer<aws_mqtt_client>

    init(rawValue _: UnsafeMutablePointer<aws_mqtt_client>, clientBootstrap: ClientBootstrap) {
        self.rawValue = aws_mqtt_client_new(defaultAllocator, clientBootstrap.rawValue)
    }

    public init(clientBootstrap: ClientBootstrap, allocator: Allocator = defaultAllocator) throws {
        self.rawValue = aws_mqtt_client_new(allocator.rawValue, clientBootstrap.rawValue)
    }

    /// Creates a new mqtt connection to the host on the port given using TLS
    /// - Parameters:
    ///   - host: The host to connection i.e. www.example.com as a `String`
    ///   - port: The port number to connect on i.e. 443
    ///   - socketOptions: Socket options  such as keep alive time in a `SocketOptions` object
    ///   - tlsContext: TLS context configuration as `TlsContext`
    ///   - useWebSockets: Set to `True` to connect over web sockets
    ///   - allocator: The allocator instance to allocate memory on
    /// - Returns: `MqttConnection`
    public func newConnection(host: String,
                              port: Int16,
                              socketOptions: SocketOptions,
                              tlsContext: TlsContext,
                              useWebSockets: Bool,
                              allocator: Allocator) -> MqttConnection {
        MqttConnection(clientPointer: rawValue,
                       host: host,
                       port: port,
                       socketOptions: socketOptions,
                       useWebSockets: useWebSockets,
                       tlsContext: tlsContext,
                       allocator: allocator)
    }

    /// Creaets a new mqtt connection to the host on the port given without TLS (not recommended).
    /// - Parameters:
    ///   - host: The host to connection i.e. www.example.com as a `String`
    ///   - port: The port number to connect on i.e. 443
    ///   - socketOptions: Socket options  such as keep alive time in a `SocketOptions` object
    ///   - useWebSockets: Set to `True` to connect over web sockets
    ///   - allocator: The allocator instance to allocate memory on
    /// - Returns: `MqttConnection`
    public func newConnection(host: String,
                              port: Int16,
                              socketOptions: SocketOptions,
                              useWebSockets: Bool,
                              allocator: Allocator) -> MqttConnection {
        MqttConnection(clientPointer: rawValue,
                       host: host,
                       port: port,
                       socketOptions: socketOptions,
                       useWebSockets: useWebSockets,
                       allocator: allocator)
    }

    deinit {
        aws_mqtt_client_release(rawValue)
    }
}
