//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCMqtt

public final class MqttClient {

    let rawValue: UnsafeMutablePointer<aws_mqtt_client>

    init(rawValue: UnsafeMutablePointer<aws_mqtt_client>, clientBootstrap: ClientBootstrap) {
        self.rawValue = rawValue
        aws_mqtt_client_init(rawValue, defaultAllocator, clientBootstrap.rawValue)
    }

    init(clientBootstrap: ClientBootstrap, allocator: Allocator = defaultAllocator) throws {
        let clientPtr = UnsafeMutablePointer<aws_mqtt_client>.allocate(capacity: 1)

        if aws_mqtt_client_init(clientPtr, allocator.rawValue, clientBootstrap.rawValue) == AWS_OP_SUCCESS {
            self.rawValue = clientPtr
        } else {
            clientPtr.deinitializeAndDeallocate()
            throw AwsCommonRuntimeError()
        }
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
    func newConnection(host: String,
                       port: Int16,
                       socketOptions: SocketOptions,
                       tlsContext: TlsContext,
                       useWebSockets: Bool,
                       allocator: Allocator) -> MqttConnection {
        return MqttConnection(clientPointer: rawValue,
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
    func newConnection(host: String,
                       port: Int16,
                       socketOptions: SocketOptions,
                       useWebSockets: Bool,
                       allocator: Allocator) -> MqttConnection {
        return MqttConnection(clientPointer: rawValue,
                              host: host,
                              port: port,
                              socketOptions: socketOptions,
                              useWebSockets: useWebSockets,
                              allocator: allocator)
    }

    deinit {
        aws_mqtt_client_clean_up(rawValue)
    }
}
