//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCMqtt

class MqttClient {
    
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
                              tlsContext: tlsContext,
                              useWebSockets: useWebSockets,
                              allocator: allocator)
    }
    
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
