//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCMqtt
import AwsCHttp
import Foundation

public typealias OnConnectionInterrupted =  (UnsafeMutablePointer<aws_mqtt_client_connection>, Int32) -> Void
public typealias OnConnectionResumed = (UnsafeMutablePointer<aws_mqtt_client_connection>, MqttReturnCode, Bool) -> Void
public typealias OnDisconnect = (UnsafeMutablePointer<aws_mqtt_client_connection>) -> Void
public typealias OnConnectionComplete = (UnsafeMutablePointer<aws_mqtt_client_connection>, Int32, MqttReturnCode, Bool) -> Void
public typealias OnWebSocketHandshakeIntercept = (HttpRequest, OnWebSocketHandshakeInterceptComplete?) -> Void
public typealias OnWebSocketHandshakeInterceptComplete = (HttpRequest, Int32) -> Void

public class MqttConnection {
    var onConnectionInterrupted: OnConnectionInterrupted = {(connectionPtr, errorCode) in }
    var onConnectionResumed: OnConnectionResumed = {(connectionPtr, returnCode, retain) in }
    var onDisconnect: OnDisconnect = {(connectionPtr) in }
    var onConnectionComplete:OnConnectionComplete = {(connectionPtr, errorCode, returnCode, retain) in}
    var onWebSocketHandshakeIntercept: OnWebSocketHandshakeIntercept? = nil
    var onWebSocketHandshakeInterceptComplete: OnWebSocketHandshakeInterceptComplete? = nil
    
    private var allocator: Allocator
    private var clientPointer: UnsafeMutablePointer<aws_mqtt_client>
    let rawValue: UnsafeMutablePointer<aws_mqtt_client_connection>
    let port: Int16
    let host: String
    let socketOptions: SocketOptions
    let useWebSockets: Bool
    let tlsContext: TlsContext?
    var proxyOptions: HttpClientConnectionProxyOptions? = nil
    var pubCallbackData: UnsafeMutablePointer<PubCallbackData>? = nil
    
    convenience init(clientPointer: UnsafeMutablePointer<aws_mqtt_client>,
                     host: String,
                     port: Int16,
                     socketOptions: SocketOptions,
                     tlsContext: TlsContext,
                     useWebSockets: Bool,
                     allocator: Allocator = defaultAllocator) {
        
        self.init(clientPointer: clientPointer,
                  host: host,
                  port: port,
                  socketOptions: socketOptions,
                  useWebSockets: useWebSockets,
                  tlsContext: tlsContext,
                  allocator: allocator)
    }
    
    init(clientPointer: UnsafeMutablePointer<aws_mqtt_client>,
         host: String,
         port: Int16,
         socketOptions: SocketOptions,
         useWebSockets: Bool,
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
        
        setUpCallbackData()
    }
    
    private func setUpCallbackData() {

        aws_mqtt_client_connection_set_connection_interruption_handlers(rawValue, { (clientConnectionPointer, errorCode, userData) in
            guard let userData = userData else {
                return
            }
            
            let pointer = userData.assumingMemoryBound(to: MqttConnection.self)
            
            pointer.pointee.onConnectionInterrupted(pointer.pointee.rawValue, errorCode)
            
            
        }, rawValue, { (clientConnectionPointer, connectReturnCode, sessionPresent, userData) in
            guard let userData = userData else {
                return
            }
            
            let pointer = userData.assumingMemoryBound(to: MqttConnection.self)
            
            pointer.pointee.onConnectionResumed(pointer.pointee.rawValue, MqttReturnCode(rawValue: connectReturnCode), sessionPresent)
            
        }, rawValue)
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
        let connectionPtr = UnsafeMutablePointer<MqttConnection>.allocate(capacity: 1)
        connectionPtr.initialize(to: self)
        let ptr = UnsafeMutableRawPointer(connectionPtr)
        mqttOptions.user_data = ptr
        
        mqttOptions.on_connection_complete = { (connectionPtr, errorCode, returnCode, sessionPresent, userData) in
            guard let userData = userData else {
                return
            }
           
            let callbackPtr = userData.assumingMemoryBound(to: MqttConnection.self)
            defer {
                callbackPtr.deinitializeAndDeallocate()
            }
            callbackPtr.pointee.onConnectionComplete(callbackPtr.pointee.rawValue, errorCode,
                                                         MqttReturnCode(rawValue: returnCode), sessionPresent)
        }
        
        if useWebSockets {
            if let _ = onWebSocketHandshakeIntercept {

                if aws_mqtt_client_connection_use_websockets(rawValue, { (httpRequest, userData, completeFn, completeUserData) in
                    guard let userData = userData,
                        let httpRequest = httpRequest else {
                        return
                    }
                    let ptr = userData.assumingMemoryBound(to: MqttConnection.self)

                    let onInterceptComplete: OnWebSocketHandshakeInterceptComplete = {request,errorCode in
                        completeFn!(httpRequest, errorCode, completeUserData)
                    }
                    //can unwrap here with ! because we know its not nil at this point
                    ptr.pointee.onWebSocketHandshakeIntercept!(HttpRequest(message: httpRequest), onInterceptComplete)
                }, rawValue, nil, nil) == AWS_OP_SUCCESS {
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
        defer {
            mqttOptionsPtr.deinitializeAndDeallocate()
            tlsOptionsPtr?.deinitializeAndDeallocate()
            socketOptionsPtr.deinitializeAndDeallocate()
        }
        
        return aws_mqtt_client_connection_connect(rawValue, mqttOptionsPtr) == AWS_OP_SUCCESS
    }
    
    func disconnect() -> Bool {
       
       return aws_mqtt_client_connection_disconnect(rawValue, { (connectionPtr, userData) in
            guard let userData = userData else {
                return
            }
            let connectionPtr = userData.assumingMemoryBound(to: MqttConnection.self)

        connectionPtr.pointee.onDisconnect(connectionPtr.pointee.rawValue)
        }, rawValue) == AWS_OP_SUCCESS
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
            
        }, ptr) == AWS_OP_SUCCESS {
            self.pubCallbackData = ptr
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
        
        defer {
            pointers.deinitializeAndDeallocate()
        }
        
        return Int16(packetId)
    }
    
    deinit {
        aws_mqtt_client_connection_destroy(rawValue)
        if let pubCallbackData = pubCallbackData {
            pubCallbackData.deinitializeAndDeallocate()
        }
    }
}
