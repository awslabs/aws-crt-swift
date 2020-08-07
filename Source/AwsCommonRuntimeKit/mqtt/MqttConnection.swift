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
    var onConnectionComplete: OnConnectionComplete = {(connectionPtr, errorCode, returnCode, retain) in}
    var onWebSocketHandshakeIntercept: OnWebSocketHandshakeIntercept?
    var onWebSocketHandshakeInterceptComplete: OnWebSocketHandshakeInterceptComplete?

    private var allocator: Allocator
    private var clientPointer: UnsafeMutablePointer<aws_mqtt_client>
    let rawValue: UnsafeMutablePointer<aws_mqtt_client_connection>
    let port: Int16
    let host: String
    let socketOptions: SocketOptions
    let useWebSockets: Bool
    let tlsContext: TlsContext?
    var proxyOptions: HttpClientConnectionProxyOptions?
    var pubCallbackData: UnsafeMutablePointer<PubCallbackData>?

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

        }, rawValue, { (_, connectReturnCode, sessionPresent, userData) in
            guard let userData = userData else {
                return
            }

            let pointer = userData.assumingMemoryBound(to: MqttConnection.self)

            pointer.pointee.onConnectionResumed(pointer.pointee.rawValue, MqttReturnCode(rawValue: connectReturnCode), sessionPresent)

        }, rawValue)
    }

    /// Sets the will message to send with the CONNECT packet.
    /// - Parameters:
    ///   - topic: The topic to publish the will on
    ///   - qos: The QoS to publish the will with of type `MqttQos`
    ///   - retain: True to have the server save the packet, and send to all new subscriptions matching topic
    ///   - payload: The payload of the will message to send over as `Data`
    /// - Returns: A `Bool` if will was set successfully
    func setWill(topic: String, qos: MqttQos, retain: Bool, payload: Data) -> Bool {
        let pointers = UnsafeMutablePointer<aws_byte_cursor>.allocate(capacity: 2)
        pointers.initialize(to: topic.awsByteCursor)
        pointers.advanced(by: 1).initialize(to: payload.awsByteCursor)

        return aws_mqtt_client_connection_set_will(rawValue, pointers, qos.rawValue, retain, pointers.advanced(by: 1)) == AWS_OP_SUCCESS
    }

    /// Sets the username and/or password to send with the CONNECT packet.
    /// - Parameters:
    ///   - username: Username to send over as `String`
    ///   - password: Password to authenticate with as `String`
    /// - Returns: A  `Bool` if login was set successfully.
    func setLogin(username: String, password: String) -> Bool {
        let pointers = UnsafeMutablePointer<aws_byte_cursor>.allocate(capacity: 1)
        pointers.initialize(to: username.awsByteCursor)
        pointers.advanced(by: 1).initialize(to: password.awsByteCursor)
        return aws_mqtt_client_connection_set_login(rawValue, pointers, pointers.advanced(by: 1)) == AWS_OP_SUCCESS
    }

    /// Opens the actual connection defined this class. Once the connection is opened, `OnConnectionComplete` will be called.
    /// - Parameters:
    ///   - clientId: The ClientId to place in the CONNECT packet.
    ///   - cleanSession: True to discard all server session data and start fresh.
    ///   - keepAliveTime: The keep alive value to place in the CONNECT PACKET, a PING will automatically
    ///   be sent at this interval as well. If you specify 0, defaults will be used and a ping will be sent once per 20 minutes.
    ///   This duration must be longer than `requestTimeoutMs`.
    ///   - requestTimeoutMs: Network connection is re-established if a ping response is not received within this amount of time (milliseconds).
    ///    If you specify 0, a default value of 3 seconds is used. Alternatively, tcp keep-alive may be away to accomplish this in a more efficient
    ///    (low-power) scenario, but keep-alive options may not work the same way on every platform and OS version. This duration must be shorter
    ///     than `keepAliveTime`.
    /// - Returns: A `Bool`of True  if operation to connect has been successfully initated.
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

                    let onInterceptComplete: OnWebSocketHandshakeInterceptComplete = {request, errorCode in
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

    /// Closes the connection asyncronously, calls the `OnDisconnect` callback, and destroys the connection object.
    /// - Returns: A `Bool` of True if the connection is open and is being shut down.
    func disconnect() -> Bool {

       return aws_mqtt_client_connection_disconnect(rawValue, { (connectionPtr, userData) in
            guard let userData = userData else {
                return
            }
            let connectionPtr = userData.assumingMemoryBound(to: MqttConnection.self)

        connectionPtr.pointee.onDisconnect(connectionPtr.pointee.rawValue)
        }, rawValue) == AWS_OP_SUCCESS
    }

    /// Sets the callback to call whenever ANY publish packet is received.
    /// - Parameter onPublishReceived: The function to call when a publish is received
    /// - Returns: A `Bool` of True if the callback was set successfully
    func setOnMessageHandler(onPublishReceived: @escaping OnPublishReceived) -> Bool {
        let pubCallbackData = PubCallbackData(onPublishReceived: onPublishReceived,
                                              mqttConnection: self)

        let ptr = UnsafeMutablePointer<PubCallbackData>.allocate(capacity: 1)
        ptr.initialize(to: pubCallbackData)

        if aws_mqtt_client_connection_set_on_any_publish_handler(rawValue, { (_, topic, payload, userData) in
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

    /// Subscribe to a single topic filter. `OnPublishReceived` will be called when a PUBLISH matching `topicFilter` is received.
    /// - Parameters:
    ///   - topicFilter: The topic filter to subscribe on.  This resource must persist until `OnSubAck` is called.
    ///   - qos: The maximum QoS of messages to receive
    ///   - onPublishReceived: Called when a PUBLISH packet matching `topicFilter` is received
    ///   - onSubAck: Called when a SUBACK has been received from the server and the subscription is complete
    /// - Returns: The packet id of the subscribe packet if successfully sent, otherwise 0.
    func subscribe(topicFilter: String,
                   qos: MqttQos,
                   onPublishReceived: @escaping OnPublishReceived,
                   onSubAck: @escaping OnSubAck) -> UInt16 {

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
        }, pubCallbackPtr, nil, { (_, packetId, topic, qos, errorCode, userData) in
            guard let userData = userData, let topic = topic?.pointee.toString() else {
                return
            }
            let ptr = userData.assumingMemoryBound(to: SubAckCallbackData.self)
            defer {ptr.deinitializeAndDeallocate()}
            ptr.pointee.onSubAck(ptr.pointee.connection, Int16(packetId), topic, MqttQos(rawValue: qos), errorCode)
        }, subAckCallbackPtr)

        return packetId
    }

    /// Subscribe to topic filters. `onMultiSubAck` will be called when a PUBLISH matching each `topicFilter`is received.
    /// - Parameters:
    ///   - topicFilters: An array of topic filters describing the requests
    ///   - onMultiSubAck: Called when a SUBACK has been received from the server and the subscription is complete
    /// - Returns: The packet id of the subscribe packet if successfully sent, otherwise 0.
    func subscribe(topicFilters: [String],
                   onMultiSubAck: @escaping OnMultiSubAck) -> UInt16 {

        let subAckCallbackData = MultiSubAckCallbackData(onMultiSubAck: onMultiSubAck, connection: self, topics: topicFilters)
        let subAckCallbackPtr = UnsafeMutablePointer<MultiSubAckCallbackData>.allocate(capacity: 1)
        subAckCallbackPtr.initialize(to: subAckCallbackData)

        let stringPointers = UnsafeMutablePointer<String>.allocate(capacity: topicFilters.count)

        for index in 0...topicFilters.count {
            stringPointers.advanced(by: index).initialize(to: topicFilters[index])
        }

        let untypedPointers = UnsafeMutableRawPointer(stringPointers)

        var awsArray = aws_array_list()
        awsArray.current_size = topicFilters.count
        awsArray.item_size = MemoryLayout.size(ofValue: String.self)
        awsArray.data = untypedPointers
        let arrayPointer = UnsafeMutablePointer<aws_array_list>.allocate(capacity: 1)

        let packetId = aws_mqtt_client_connection_subscribe_multiple(rawValue, arrayPointer, { (_, packetId, topicPointers, errorCode, userData) in
            guard let userData = userData, let topicPointers = topicPointers else {
                return
            }
            let ptr = userData.assumingMemoryBound(to: MultiSubAckCallbackData.self)
            defer {ptr.deinitializeAndDeallocate()}
            var topics = [String]()
            for index in 0...topicPointers.pointee.current_size {
                let pointer = topicPointers.pointee.data.advanced(by: index)
                let swiftString = pointer.assumingMemoryBound(to: String.self)
                topics.append(swiftString.pointee)
            }

            ptr.pointee.onMultiSubAck(ptr.pointee.connection, Int16(packetId), topics, errorCode)
        }, subAckCallbackPtr)

        return packetId
    }

    /// Unsubscribe to a topic filter.
    /// - Parameters:
    ///   - topicFilter: The topic filter to unsubscribe on. This resource must persist until `onComplete`.
    ///   - onComplete: Called when a UNSUBACK has been received from the server and the subscription is removed
    /// - Returns: The packet id of the unsubscribe packet if successfully sent, otherwise 0.
    func unsubscribe(topicFilter: String, onComplete: @escaping OnOperationComplete) -> UInt16 {
        let opCallbackData = OpCompleteCallbackData(connection: self, onOperationComplete: onComplete)
        let opCallbackPtr = UnsafeMutablePointer<OpCompleteCallbackData>.allocate(capacity: 1)
        opCallbackPtr.initialize(to: opCallbackData)
        let topicPtr = UnsafeMutablePointer<aws_byte_cursor>.allocate(capacity: 1)
        topicPtr.initialize(to: topicFilter.awsByteCursor)
        let packetId = aws_mqtt_client_connection_unsubscribe(rawValue, topicPtr, { (_, packetId, errorCode, userData) in
            guard let userData = userData else {
                return
            }
            let ptr = userData.assumingMemoryBound(to: OpCompleteCallbackData.self)
            defer {
                ptr.deinitializeAndDeallocate()
            }
            ptr.pointee.onOperationComplete(ptr.pointee.connection, Int16(packetId), errorCode)
        }, opCallbackPtr)
        return packetId
    }

    /// Send a PUBLSIH packet over connection.
    /// - Parameters:
    ///   - topic: The topic to publish on.
    ///   - qos: The requested QoS of the packet.
    ///   - retain: True to have the server save the packet, and send to all new subscriptions matching topic
    ///   - payload: The data to send as the payload of the publish
    ///   - onComplete: For QoS `.atMostOnce`, called as soon as the packet is sent. For QoS `.atLeastOnce`, called when PUBACK is received. For QoS `.exactlyOnce`, called when PUBCOMP is received
    /// - Returns: The packet id of the publish packet if successfully sent, otherwise 0.
    func publish(topic: String, qos: MqttQos, retain: Bool, payload: Data, onComplete: @escaping OnOperationComplete) -> UInt16 {
        let opCallbackData = OpCompleteCallbackData(topic: topic, connection: self, onOperationComplete: onComplete)
        let opCallbackPtr = UnsafeMutablePointer<OpCompleteCallbackData>.allocate(capacity: 1)
        opCallbackPtr.initialize(to: opCallbackData)
        let pointers = UnsafeMutablePointer<aws_byte_cursor>.allocate(capacity: 2)
        pointers.initialize(to: topic.awsByteCursor)
        pointers.advanced(by: 1).initialize(to: payload.awsByteCursor)

        let packetId = aws_mqtt_client_connection_publish(rawValue, pointers, qos.rawValue, retain, pointers.advanced(by: 1), { (_, packetId, errorCode, userData) in
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

        return packetId
    }

    deinit {
        aws_mqtt_client_connection_destroy(rawValue)
        if let pubCallbackData = pubCallbackData {
            pubCallbackData.deinitializeAndDeallocate()
        }
    }
}
