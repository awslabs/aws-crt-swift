//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCMqtt
import AwsCHttp
import Foundation

public class MqttConnection {
    private var allocator: Allocator
    private var clientPointer: UnsafeMutablePointer<aws_mqtt_client>
    let rawValue: UnsafeMutablePointer<aws_mqtt_client_connection>
    let port: Int16
    let host: String
    let socketOptions: SocketOptions
    let useWebSockets: Bool
    let tlsContext: TlsContext?
    var callbackData: MqttConnectionCallbackData?
    var proxyOptions: HttpClientConnectionProxyOptions? = nil
    
    convenience init(clientPointer: UnsafeMutablePointer<aws_mqtt_client>,
                     host: String,
                     port: Int16,
                     socketOptions: SocketOptions,
                     tlsContext: TlsContext,
                     useWebSockets: Bool,
                     callbackData: MqttConnectionCallbackData? = nil,
                     allocator: Allocator = defaultAllocator) {
        
        self.init(clientPointer: clientPointer,
                  host: host,
                  port: port,
                  socketOptions: socketOptions,
                  useWebSockets: useWebSockets,
                  callbackData: callbackData,
                  tlsContext: tlsContext,
                  allocator: allocator)
    }
    
    init(clientPointer: UnsafeMutablePointer<aws_mqtt_client>,
         host: String,
         port: Int16,
         socketOptions: SocketOptions,
         useWebSockets: Bool,
         callbackData: MqttConnectionCallbackData? = nil,
         tlsContext: TlsContext? = nil,
         allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
        self.clientPointer = clientPointer
        self.port = port
        self.host = host
        self.useWebSockets = useWebSockets
        self.socketOptions = socketOptions
        self.tlsContext = tlsContext
        self.rawValue = aws_mqtt_client_connection_new(clientPointer)
        self.callbackData = callbackData
        if let callbackData = callbackData {
            setUpCallbackData(callbackData: callbackData)
        }
    }
    
    private func setUpCallbackData(callbackData: MqttConnectionCallbackData) {
        let onConnectionInterruptedPtr = UnsafeMutablePointer<OnConnectionInterrupted>.allocate(capacity: 1)
        onConnectionInterruptedPtr.initialize(to: callbackData.onConnectionInterrupted)
        
        let onConnectionResumedPtr = UnsafeMutablePointer<OnConnectionResumed>.allocate(capacity: 1)
        onConnectionResumedPtr.initialize(to: callbackData.onConnectionResumed)
        
        aws_mqtt_client_connection_set_connection_interruption_handlers(rawValue, { (clientConnectionPointer, errorCode, userData) in
            guard let userData = userData else {
                return
            }
            
            let pointer = userData.assumingMemoryBound(to: MqttConnectionCallbackData.self)
            defer { pointer.deinitializeAndDeallocate()}
            
            pointer.pointee.onConnectionInterrupted(clientConnectionPointer, errorCode)
            
            
        }, onConnectionInterruptedPtr, { (clientConnectionPointer, connectReturnCode, sessionPresent, userData) in
            guard let userData = userData else {
                return
            }
            
            let pointer = userData.assumingMemoryBound(to: MqttConnectionCallbackData.self)
            defer {
                pointer.deinitializeAndDeallocate()
            }
            
            pointer.pointee.onConnectionResumed(clientConnectionPointer, MqttReturnCode(rawValue: connectReturnCode), sessionPresent)
            
        }, onConnectionResumedPtr)
    }
    
    func setWill(topic: String, qos: MqttQos, retain: Bool, payload: Data) -> Bool {
        let pointers = UnsafeMutablePointer<aws_byte_cursor>.allocate(capacity: 2)
        pointers.initialize(to: topic.awsByteCursor)
        pointers.advanced(by: 1).initialize(to: payload.awsByteCursor)

        return aws_mqtt_client_connection_set_will(rawValue, pointers, qos.rawValue, retain, pointers.advanced(by: 1)) == AWS_OP_SUCCESS
    }
    
    func setLogin(username: String, password: String) -> Bool {
        let pointers = UnsafeMutablePointer<aws_byte_cursor>.allocate(capacity: 1)
        pointers.initialize(to: username.awsByteCursor)
        pointers.advanced(by: 1).initialize(to: password.awsByteCursor)
        return aws_mqtt_client_connection_set_login(rawValue, pointers, pointers.advanced(by: 1)) == AWS_OP_SUCCESS
    }
    
    func connect(clientId: String, cleanSession: Bool, keepAliveTime: Int16, requestTimeoutMs: Int32) -> Bool {
        let socketOptionsPtr = UnsafeMutablePointer<aws_socket_options>.allocate(capacity: 1)
        socketOptionsPtr.initialize(to: socketOptions.rawValue)
        var tlsOptionsPtr: UnsafeMutablePointer<aws_tls_connection_options>?
        if let tlsContext = tlsContext {
        
        tlsOptionsPtr = UnsafeMutablePointer<aws_tls_connection_options>.allocate(capacity: 1)
        tlsOptionsPtr?.initialize(to: tlsContext.newConnectionOptions().rawValue)
        }
        
        
        var mqttOptions = aws_mqtt_connection_options()
        mqttOptions.host_name = host.awsByteCursor
        mqttOptions.port = UInt16(port)
        mqttOptions.socket_options = socketOptionsPtr
        mqttOptions.tls_options = tlsOptionsPtr
        mqttOptions.client_id = clientId.awsByteCursor
        mqttOptions.keep_alive_time_secs = UInt16(keepAliveTime)
        mqttOptions.ping_timeout_ms = UInt32(requestTimeoutMs)
        mqttOptions.clean_session = cleanSession
        if let callbackData = callbackData {
            let callbackDataPtr = UnsafeMutablePointer<MqttConnectionCallbackData>.allocate(capacity: 1)
            callbackDataPtr.initialize(to: callbackData)
            let ptr = UnsafeMutableRawPointer(callbackDataPtr)
            mqttOptions.user_data = ptr
            
            mqttOptions.on_connection_complete = { (connectionPtr, errorCode, returnCode, sessionPresent, userData) in
                guard let userData = userData else {
                    return
                }
                let callbackPtr = userData.assumingMemoryBound(to: MqttConnectionCallbackData.self)
                defer {
                    callbackPtr.deinitializeAndDeallocate()
                }
                callbackPtr.pointee.onConnectionComplete(connectionPtr, errorCode,
                                                             MqttReturnCode(rawValue: returnCode), sessionPresent)
            }
        }
        
        if useWebSockets {
            if let callbackData = callbackData,
                let _ = callbackData.onWebSocketHandshakeIntercept {
                let interceptorPtr = UnsafeMutablePointer<MqttConnectionCallbackData>.allocate(capacity: 1)
                interceptorPtr.initialize(to: callbackData)
                if aws_mqtt_client_connection_use_websockets(rawValue, { (httpRequest, userData, completeFn, completeUserData) in
                    guard let userData = userData,
                        let httpRequest = httpRequest else {
                        return
                    }
                    let ptr = userData.assumingMemoryBound(to: MqttConnectionCallbackData.self)
                    defer {
                        ptr.deinitializeAndDeallocate()
                    }
                    
                    let onInterceptComplete: OnWebSocketHandshakeInterceptComplete = {request,errorCode in
                        completeFn!(httpRequest, errorCode, completeUserData)
                    }
                    //can unwrap here with ! because we know its not nil at this point
                    ptr.pointee.onWebSocketHandshakeIntercept!(HttpRequest(message: httpRequest), onInterceptComplete)
                }, interceptorPtr, nil, nil) == AWS_OP_SUCCESS {
                    return false
                }
            } else {
                if aws_mqtt_client_connection_use_websockets(rawValue, nil, nil, nil, nil) == AWS_OP_SUCCESS {
                    return false
                }
            }
            
            if let proxyOptions = proxyOptions {
                
                var pOptions = aws_http_proxy_options()
                pOptions.auth_username = proxyOptions.basicAuthUsername.awsByteCursor
                pOptions.auth_password = proxyOptions.basicAuthPassword.awsByteCursor
                if let tlsOptions = proxyOptions.tlsOptions?.rawValue {
                    let tlsPtr = UnsafeMutablePointer<aws_tls_connection_options>.allocate(capacity: 1)
                    tlsPtr.initialize(to: tlsOptions)
                    pOptions.tls_options = tlsPtr
                }
                pOptions.auth_type = proxyOptions.authType.rawValue
                pOptions.host = proxyOptions.hostName.awsByteCursor
                pOptions.port = proxyOptions.port
                
                let ptr = UnsafeMutablePointer<aws_http_proxy_options>.allocate(capacity: 1)
                ptr.initialize(to: pOptions)
                
                if aws_mqtt_client_connection_set_websocket_proxy_options(rawValue, ptr) == AWS_OP_SUCCESS {
                    return false
                }
            }
        }
        
        let mqttOptionsPtr = UnsafeMutablePointer<aws_mqtt_connection_options>.allocate(capacity: 1)
        mqttOptionsPtr.initialize(to: mqttOptions)
        
        return aws_mqtt_client_connection_connect(rawValue, mqttOptionsPtr) == AWS_OP_SUCCESS
    }
    
    func disconnect() -> Bool {
        if let callbackData = callbackData {
            let pointer = UnsafeMutablePointer<MqttConnectionCallbackData>.allocate(capacity: 1)
            pointer.initialize(to: callbackData)
           return aws_mqtt_client_connection_disconnect(rawValue, { (connectionPtr, userData) in
                guard let userData = userData else {
                    return
                }
                let callbackDataPtr = userData.assumingMemoryBound(to: MqttConnectionCallbackData.self)
                defer {
                    callbackDataPtr.deinitializeAndDeallocate()
                }
                callbackDataPtr.pointee.onDisconnect(connectionPtr)
            }, pointer) == AWS_OP_SUCCESS
        }
        
        return false
    }
    
    func setOnMessageHandler(onPublishReceived: @escaping OnPublishReceived) -> Bool {
        let pubCallbackData = PubCallbackData(onPublishReceived: onPublishReceived,
                                              mqttConnection: self)
        
        let ptr = UnsafeMutablePointer<PubCallbackData>.allocate(capacity: 1)
        ptr.initialize(to: pubCallbackData)
        
        if aws_mqtt_client_connection_set_on_any_publish_handler(rawValue, { (connectionPtr, topic, payload, userData) in
            guard let userData = userData, let topic = topic?.pointee.toString(), let payload = payload else {
                return
            }
            
            let pubCallbackPtr = userData.assumingMemoryBound(to: PubCallbackData.self)
            defer {
                pubCallbackPtr.deinitializeAndDeallocate()
            }
            pubCallbackPtr.pointee.onPublishReceived(pubCallbackPtr.pointee.mqttConnection, topic, payload.pointee.toData())
            
        }, ptr) != AWS_OP_SUCCESS {
            return true
        }
        
        defer {
            ptr.deinitializeAndDeallocate()
        }
        
        return false
    }
    
    func subscribe(topicFilter: String,
                   qos: MqttQos,
                   onPublishReceived: @escaping OnPublishReceived,
                   onSubAck: @escaping OnSubAck) -> Int16 {
       
        let pubCallbackData = PubCallbackData(onPublishReceived: onPublishReceived, mqttConnection: self)
        let pubCallbackPtr = UnsafeMutablePointer<PubCallbackData>.allocate(capacity: 1)
        pubCallbackPtr.initialize(to: pubCallbackData)
        let subAckCallbackData = SubAckCallbackData(onSubAck: onSubAck, connection: self, topic: nil)
        let subAckCallbackPtr = UnsafeMutablePointer<SubAckCallbackData>.allocate(capacity: 1)
        subAckCallbackPtr.initialize(to: subAckCallbackData)
        let topicPtr = UnsafeMutablePointer<aws_byte_cursor>.allocate(capacity: 1)
        topicPtr.initialize(to: topicFilter.awsByteCursor)
        let packetId = aws_mqtt_client_connection_subscribe(rawValue, topicPtr, qos.rawValue, { (connectionPtr, topic, payload, userData) in
            guard let userData = userData, let topic = topic?.pointee.toString(), let payload = payload else {
                return
            }
            let ptr = userData.assumingMemoryBound(to: PubCallbackData.self)
            defer {ptr.deinitializeAndDeallocate()}
            ptr.pointee.onPublishReceived(ptr.pointee.mqttConnection, topic, payload.pointee.toData())
        }, pubCallbackPtr, nil, { (connectionPtr, packetId, topic, qos, errorCode, userData) in
            guard let userData = userData, let topic = topic?.pointee.toString() else {
                return
            }
            let ptr = userData.assumingMemoryBound(to: SubAckCallbackData.self)
            defer {ptr.deinitializeAndDeallocate()}
            ptr.pointee.onSubAck(ptr.pointee.connection, Int16(packetId), topic, MqttQos(rawValue: qos), errorCode)
        }, subAckCallbackPtr)
        
        return Int16(packetId)
    }
    
    func unsubscribe(topicFilter: String, onComplete: @escaping OnOperationComplete) -> Int16 {
        let opCallbackData = OpCompleteCallbackData(connection: self, onOperationComplete: onComplete)
        let opCallbackPtr = UnsafeMutablePointer<OpCompleteCallbackData>.allocate(capacity: 1)
        opCallbackPtr.initialize(to: opCallbackData)
        let topicPtr = UnsafeMutablePointer<aws_byte_cursor>.allocate(capacity: 1)
        topicPtr.initialize(to: topicFilter.awsByteCursor)
        let packetId = aws_mqtt_client_connection_unsubscribe(rawValue, topicPtr, { (connectionPtr, packetId, errorCode, userData) in
            guard let userData = userData else {
                return
            }
            let ptr = userData.assumingMemoryBound(to: OpCompleteCallbackData.self)
            defer { ptr.deinitializeAndDeallocate()}
            ptr.pointee.onOperationComplete(ptr.pointee.connection, Int16(packetId), errorCode)
        }, opCallbackPtr)
        return Int16(packetId)
    }
    
    func publish(topic: String, qos: MqttQos, retain: Bool, payload: Data, onComplete: @escaping OnOperationComplete) -> Int16 {
        let opCallbackData = OpCompleteCallbackData(topic: topic, connection: self, onOperationComplete: onComplete)
        let opCallbackPtr = UnsafeMutablePointer<OpCompleteCallbackData>.allocate(capacity: 1)
        opCallbackPtr.initialize(to: opCallbackData)
        let pointers = UnsafeMutablePointer<aws_byte_cursor>.allocate(capacity: 2)
        pointers.initialize(to: topic.awsByteCursor)
        pointers.advanced(by: 1).initialize(to: payload.awsByteCursor)
        
        let packetId = aws_mqtt_client_connection_publish(rawValue, pointers, qos.rawValue, retain, pointers.advanced(by: 1), { (connectionPtr, packetId, errorCode, userData) in
            guard let userData = userData else {
                return
            }
            let ptr = userData.assumingMemoryBound(to: OpCompleteCallbackData.self)
            defer { ptr.deinitializeAndDeallocate()}
            ptr.pointee.onOperationComplete(ptr.pointee.connection, Int16(packetId), errorCode)
        }, opCallbackPtr)
        
        return Int16(packetId)
    }
    
    deinit {
        aws_mqtt_client_connection_destroy(rawValue)
    }
    
}
