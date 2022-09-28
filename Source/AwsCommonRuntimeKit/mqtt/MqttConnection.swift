//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp
import AwsCMqtt
import Foundation

public typealias OnConnectionInterrupted = (UnsafeMutablePointer<aws_mqtt_client_connection>,
                                            CRTError) -> Void
public typealias OnConnectionResumed = (UnsafeMutablePointer<aws_mqtt_client_connection>,
                                        MqttReturnCode,
                                        Bool) -> Void
public typealias OnDisconnect = (UnsafeMutablePointer<aws_mqtt_client_connection>) -> Void
public typealias OnConnectionComplete = (UnsafeMutablePointer<aws_mqtt_client_connection>,
                                         CRTError, MqttReturnCode,
                                         Bool) -> Void
public typealias OnWebSocketHandshakeIntercept = (HttpRequest,
                                                  OnWebSocketHandshakeInterceptComplete?) -> Void
public typealias OnWebSocketHandshakeInterceptComplete = (HttpRequest, CRTError) -> Void

// swiftlint:disable cyclomatic_complexity file_length type_body_length opening_brace
public class MqttConnection {
    public var onConnectionInterrupted: OnConnectionInterrupted = { _, _ in }
    public var onConnectionResumed: OnConnectionResumed = { _, _, _ in }
    public var onDisconnect: OnDisconnect = { _ in }
    public var onConnectionComplete: OnConnectionComplete = { _, _, _, _ in }
    public var onWebSocketHandshakeIntercept: OnWebSocketHandshakeIntercept?
    public var onWebSocketHandshakeInterceptComplete: OnWebSocketHandshakeInterceptComplete?

    private var allocator: Allocator
    private var clientPointer: UnsafeMutablePointer<aws_mqtt_client>
    let rawValue: UnsafeMutablePointer<aws_mqtt_client_connection>
    let port: Int16
    let host: String
    let socketOptions: SocketOptions
    let useWebSockets: Bool
    let tlsContext: TlsContext?
    var proxyOptions: HttpProxyOptions?
    var pubCallbackData: UnsafeMutablePointer<PubCallbackData>?
    /// This pointer has to live for the duration of all the callbacks that could be called so that is why we store it on the connection itself.
    var nativePointer: UnsafeMutableRawPointer?

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
        rawValue = aws_mqtt_client_connection_new(clientPointer)

        setUpCallbackData()
    }

    private func setUpCallbackData() {
        nativePointer = fromPointer(ptr: self)
        aws_mqtt_client_connection_set_connection_interruption_handlers(rawValue, { _, errorCode, userData in
            guard let userData = userData else {
                return
            }

            let pointer = userData.assumingMemoryBound(to: MqttConnection.self)

            let error = AWSError(errorCode: errorCode)

            pointer.pointee.onConnectionInterrupted(pointer.pointee.rawValue,
                                                    CRTError.crtError(error))

        }, nativePointer, { _, connectReturnCode, sessionPresent, userData in
            guard let userData = userData else {
                return
            }

            let pointer = userData.assumingMemoryBound(to: MqttConnection.self)

            pointer.pointee.onConnectionResumed(pointer.pointee.rawValue,
                                                MqttReturnCode(rawValue: connectReturnCode),
                                                sessionPresent)

        }, nativePointer)
    }

    /// Sets the will message to send with the CONNECT packet.
    /// - Parameters:
    ///   - topic: The topic to publish the will on
    ///   - qos: The QoS to publish the will with of type `MqttQos`
    ///   - retain: True to have the server save the packet, and send to all new subscriptions matching topic
    ///   - payload: The payload of the will message to send over as `Data`
    /// - Returns: A `Bool` if will was set successfully
    public func setWill(topic: String, qos: MqttQos, retain: Bool, payload: Data) -> Bool {
        var topicByteCursor = topic.awsByteCursor
        var payloadByteCursor = payload.awsByteCursor
        return aws_mqtt_client_connection_set_will(rawValue,
                                                   &topicByteCursor,
                                                   qos.rawValue,
                                                   retain,
                                                   &payloadByteCursor) == AWS_OP_SUCCESS
    }

    /// Sets the username and/or password to send with the CONNECT packet.
    /// - Parameters:
    ///   - username: Username to send over as `String`
    ///   - password: Password to authenticate with as `String`
    /// - Returns: A  `Bool` if login was set successfully.
    public func setLogin(username: String, password: String) -> Bool {
        var usernameByteCursor = username.awsByteCursor
        var passwordByteCursor = password.awsByteCursor
        return aws_mqtt_client_connection_set_login(rawValue,
                                                    &usernameByteCursor,
                                                    &passwordByteCursor) == AWS_OP_SUCCESS
    }

    /// Opens the actual connection defined this class. Once the connection is opened, `OnConnectionComplete`
    /// will be called.
    /// - Parameters:
    ///   - clientId: The ClientId to place in the CONNECT packet.
    ///   - cleanSession: True to discard all server session data and start fresh.
    ///   - keepAliveTime: The keep alive value to place in the CONNECT PACKET,
    ///   a PING will automatically
    ///   be sent at this interval as well. If you specify 0, defaults will be used and a ping will be sent once
    ///   per 20 minutes.
    ///   This duration must be longer than `requestTimeoutMs`.
    ///   - requestTimeoutMs: Network connection is re-established if a ping response is not received
    ///   within this amount of time (milliseconds). If you specify 0, a default value of 3 seconds is used.
    ///   Alternatively, tcp keep-alive may be away to accomplish this in a more efficient (low-power) scenario,
    ///   but keep-alive options may not work the same way on every platfor and OS version.
    ///   This duration must be shorter than `keepAliveTime`.
    /// - Returns: A `Bool`of True  if operation to connect has been successfully initated.
    public func connect(clientId: String,
                        cleanSession: Bool,
                        keepAliveTime: Int16,
                        requestTimeoutMs: Int32) -> Bool {
        var mqttOptions = aws_mqtt_connection_options()
        mqttOptions.host_name = host.awsByteCursor
        mqttOptions.port = UInt16(port)
        mqttOptions.socket_options = socketOptions.rawValue
        let tlsOptions = tlsContext?.newConnectionOptions()
        mqttOptions.tls_options = tlsOptions?.rawValue

        mqttOptions.client_id = clientId.awsByteCursor
        mqttOptions.keep_alive_time_secs = UInt16(keepAliveTime)
        mqttOptions.ping_timeout_ms = UInt32(requestTimeoutMs)
        mqttOptions.clean_session = cleanSession
        mqttOptions.user_data = nativePointer

        mqttOptions.on_connection_complete = { _,
            errorCode,
            returnCode,
            sessionPresent,
            userData in
            guard let userData = userData else {
                return
            }

            let callbackPtr = userData.assumingMemoryBound(to: MqttConnection.self)
            defer {
                callbackPtr.deinitializeAndDeallocate()
            }

            let error = AWSError(errorCode: errorCode)
            callbackPtr.pointee.onConnectionComplete(callbackPtr.pointee.rawValue,
                                                     CRTError.crtError(error),
                                                     MqttReturnCode(rawValue: returnCode),
                                                     sessionPresent)
        }

        if useWebSockets {
            if onWebSocketHandshakeIntercept != nil {
                aws_mqtt_client_connection_use_websockets(rawValue,
                                                          { httpRequest, userData, completeFn, completeUserData in
                                                              guard let userData = userData,
                                                                    let httpRequest = httpRequest
                                                              else {
                                                                  return
                                                              }
                                                              let ptr = userData.assumingMemoryBound(to: MqttConnection.self)

                                                              let onInterceptComplete: OnWebSocketHandshakeInterceptComplete = { _, crtError in
                                                                  if case let CRTError.crtError(error) = crtError {
                                                                      completeFn!(httpRequest, error.errorCode, completeUserData)
                                                                  }
                                                              }
                                                              defer { ptr.deinitializeAndDeallocate() }
                                                              // can unwrap here with ! because we know its not nil at this point
                                                              ptr.pointee.onWebSocketHandshakeIntercept!(HttpRequest(message: httpRequest),
                                                                                                         onInterceptComplete)
                                                          }, rawValue, nil, nil)
            } else {
                aws_mqtt_client_connection_use_websockets(rawValue, nil, nil, nil, nil)
            }

            if let proxyOptions = proxyOptions {
                var pOptions = aws_http_proxy_options()
                if let username = proxyOptions.basicAuthUsername?.awsByteCursor,
                   let password = proxyOptions.basicAuthPassword?.awsByteCursor {
                    pOptions.auth_username = username
                    pOptions.auth_password = password
                }
                if let tlsOptions = proxyOptions.tlsOptions?.rawValue {
                    let tlsPtr = UnsafePointer<aws_tls_connection_options>(tlsOptions)
                    pOptions.tls_options = tlsPtr
                }
                pOptions.auth_type = proxyOptions.authType.rawValue
                pOptions.host = proxyOptions.hostName.awsByteCursor
                pOptions.port = proxyOptions.port

                if aws_mqtt_client_connection_set_http_proxy_options(rawValue, &pOptions) != AWS_OP_SUCCESS {
                    return false
                }
            }
        }

        return aws_mqtt_client_connection_connect(rawValue, &mqttOptions) == AWS_OP_SUCCESS
    }

    /// Closes the connection asyncronously, calls the `OnDisconnect` callback, and destroys the connection object.
    /// - Returns: A `Bool` of True if the connection is open and is being shut down.
    public func disconnect() -> Bool {
        aws_mqtt_client_connection_disconnect(rawValue, { _, userData in
            guard let userData = userData else {
                return
            }
            let connectionPtr = userData.assumingMemoryBound(to: MqttConnection.self)
            defer { connectionPtr.deinitializeAndDeallocate() }

            connectionPtr.pointee.onDisconnect(connectionPtr.pointee.rawValue)
        }, rawValue) == AWS_OP_SUCCESS
    }

    /// Sets the callback to call whenever ANY publish packet is received.
    /// - Parameter onPublishReceived: The function to call when a publish is received
    /// - Returns: A `Bool` of True if the callback was set successfully
    public func setOnMessageHandler(onPublishReceived: @escaping OnPublishReceived) -> Bool {
        let pubCallbackData = PubCallbackData(onPublishReceived: onPublishReceived,
                                              mqttConnection: self)

        let ptr: UnsafeMutablePointer<PubCallbackData> = fromPointer(ptr: pubCallbackData)

        if aws_mqtt_client_connection_set_on_any_publish_handler(rawValue, { _, topic, payload, _, _, _, userData in
            guard let userData = userData, let topic = topic?.pointee.toString(), let payload = payload else {
                return
            }

            let pubCallbackPtr = userData.assumingMemoryBound(to: PubCallbackData.self)

            pubCallbackPtr.pointee.onPublishReceived(pubCallbackPtr.pointee.mqttConnection,
                                                     topic,
                                                     payload.pointee.toData())

        }, ptr) == AWS_OP_SUCCESS {
            self.pubCallbackData = ptr
            return true
        }

        return false
    }

    /// Subscribe to a single topic filter. `OnPublishReceived` will be called when a PUBLISH
    /// matching `topicFilter` is received.
    /// - Parameters:
    ///   - topicFilter: The topic filter to subscribe on.  This resource must persist until `OnSubAck` is called.
    ///   - qos: The maximum QoS of messages to receive
    ///   - onPublishReceived: Called when a PUBLISH packet matching `topicFilter` is received
    ///   - onSubAck: Called when a SUBACK has been received from the server and the subscription is complete
    /// - Returns: The packet id of the subscribe packet if successfully sent, otherwise 0.
    public func subscribe(topicFilter: String,
                          qos: MqttQos,
                          onPublishReceived: @escaping OnPublishReceived,
                          onSubAck: @escaping OnSubAck) -> UInt16 {
        let pubCallbackData = PubCallbackData(onPublishReceived: onPublishReceived, mqttConnection: self)
        let pubCallbackPtr: UnsafeMutablePointer<PubCallbackData> = fromPointer(ptr: pubCallbackData)
        let subAckCallbackData = SubAckCallbackData(onSubAck: onSubAck, connection: self, topic: nil)
        let subAckCallbackPtr: UnsafeMutablePointer<SubAckCallbackData> = fromPointer(ptr: subAckCallbackData)
        var topicByteCursor = topicFilter.awsByteCursor
        let packetId = aws_mqtt_client_connection_subscribe(rawValue,
                                                            &topicByteCursor,
                                                            qos.rawValue,
                                                            { _, topicPtr, payload, _, _, _, userData in
                                                                guard let userData = userData,
                                                                      let topic = topicPtr?.pointee.toString(),
                                                                      let payload = payload
                                                                else {
                                                                    return
                                                                }
                                                                let ptr = userData.assumingMemoryBound(to: PubCallbackData.self)

                                                                ptr.pointee.onPublishReceived(
                                                                    ptr.pointee.mqttConnection,
                                                                    topic,
                                                                    payload.pointee.toData()
                                                                )
                                                            }, pubCallbackPtr, nil, { _, packetId, topicPtr, qos, errorCode, userData in
                                                                guard let userData = userData, let topic = topicPtr?.pointee.toString() else {
                                                                    return
                                                                }
                                                                let ptr = userData.assumingMemoryBound(to: SubAckCallbackData.self)

                                                                let error = AWSError(errorCode: errorCode)
                                                                ptr.pointee.onSubAck(ptr.pointee.connection,
                                                                                     Int16(packetId),
                                                                                     topic,
                                                                                     MqttQos(rawValue: qos),
                                                                                     CRTError.crtError(error))
                                                            }, subAckCallbackPtr)

        return packetId
    }

    /// Subscribe to topic filters. `onMultiSubAck` will be called when a PUBLISH
    /// matching each `topicFilter`is received.
    /// - Parameters:
    ///   - topicFilters: An array of topic filters describing the requests
    ///   - onMultiSubAck: Called when a SUBACK has been received from the server and the subscription is complete
    /// - Returns: The packet id of the subscribe packet if successfully sent, otherwise 0.
    public func subscribe(topicFilters: [String],
                          onMultiSubAck: @escaping OnMultiSubAck) -> UInt16 {
        let subAckCallbackData = MultiSubAckCallbackData(onMultiSubAck: onMultiSubAck,
                                                         connection: self,
                                                         topics: topicFilters)
        let subAckCallbackPtr: UnsafeMutablePointer<MultiSubAckCallbackData> = fromPointer(ptr: subAckCallbackData)

        var awsArray = aws_array_list()
        awsArray.current_size = topicFilters.count
        awsArray.item_size = MemoryLayout.size(ofValue: String.self)
        awsArray.data = toPointerArray(topicFilters)

        let packetId = aws_mqtt_client_connection_subscribe_multiple(rawValue,
                                                                     &awsArray,
                                                                     { _, packetId, topicPointers, errorCode, userData
                                                                         in
                                                                         guard let userData = userData,
                                                                               let topicPointers = topicPointers
                                                                         else {
                                                                             return
                                                                         }
                                                                         let ptr = userData.assumingMemoryBound(to: MultiSubAckCallbackData.self)
                                                                         var topics = [String]()
                                                                         for index in 0 ... topicPointers.pointee.current_size {
                                                                             let pointer = topicPointers.pointee.data.advanced(by: index)
                                                                             let swiftString = pointer.assumingMemoryBound(to: String.self)
                                                                             topics.append(swiftString.pointee)
                                                                         }
                                                                         let error = AWSError(errorCode: errorCode)
                                                                         ptr.pointee.onMultiSubAck(ptr.pointee.connection,
                                                                                                   Int16(packetId),
                                                                                                   topics,
                                                                                                   CRTError.crtError(error))
                                                                     }, subAckCallbackPtr)

        return packetId
    }

    /// Unsubscribe to a topic filter.
    /// - Parameters:
    ///   - topicFilter: The topic filter to unsubscribe on. This resource must persist until `onComplete`.
    ///   - onComplete: Called when a UNSUBACK has been received from the server and the subscription is removed
    /// - Returns: The packet id of the unsubscribe packet if successfully sent, otherwise 0.
    public func unsubscribe(topicFilter: String, onComplete: @escaping OnOperationComplete) -> UInt16 {
        let opCallbackData = OpCompleteCallbackData(connection: self, onOperationComplete: onComplete)
        let opCallbackPtr: UnsafeMutablePointer<OpCompleteCallbackData> = fromPointer(ptr: opCallbackData)
        var topicByteCursor = topicFilter.awsByteCursor
        let packetId = aws_mqtt_client_connection_unsubscribe(rawValue,
                                                              &topicByteCursor,
                                                              { _, packetId, errorCode, userData in
                                                                  guard let userData = userData else {
                                                                      return
                                                                  }
                                                                  let ptr = userData.assumingMemoryBound(to: OpCompleteCallbackData.self)

                                                                  let error = AWSError(errorCode: errorCode)
                                                                  ptr.pointee.onOperationComplete(ptr.pointee.connection,
                                                                                                  Int16(packetId),
                                                                                                  CRTError.crtError(error))
                                                              }, opCallbackPtr)
        return packetId
    }

    /// Send a PUBLSIH packet over connection.
    /// - Parameters:
    ///   - topic: The topic to publish on.
    ///   - qos: The requested QoS of the packet.
    ///   - retain: True to have the server save the packet, and send to all new subscriptions matching topic
    ///   - payload: The data to send as the payload of the publish
    ///   - onComplete: For QoS `.atMostOnce`, called as soon as the packet is sent. For QoS `.atLeastOnce`,
    ///    called when PUBACK is received. For QoS `.exactlyOnce`, called when PUBCOMP is received
    /// - Returns: The packet id of the publish packet if successfully sent, otherwise 0.
    public func publish(topic: String,
                        qos: MqttQos,
                        retain: Bool,
                        payload: Data,
                        onComplete: @escaping OnOperationComplete) -> UInt16 {
        let opCallbackData = OpCompleteCallbackData(topic: topic,
                                                    connection: self,
                                                    onOperationComplete: onComplete)
        let opCallbackPtr: UnsafeMutablePointer<OpCompleteCallbackData> = fromPointer(ptr: opCallbackData)
        var topicByteCursor = topic.awsByteCursor
        var payloadByteCursor = payload.awsByteCursor
        let packetId = aws_mqtt_client_connection_publish(rawValue,
                                                          &topicByteCursor,
                                                          qos.rawValue,
                                                          retain,
                                                          &payloadByteCursor,
                                                          { _, packetId, errorCode, userData in
                                                              guard let userData = userData else {
                                                                  return
                                                              }
                                                              let ptr = userData.assumingMemoryBound(to: OpCompleteCallbackData.self)

                                                              let error = AWSError(errorCode: errorCode)
                                                              ptr.pointee.onOperationComplete(ptr.pointee.connection,
                                                                                              Int16(packetId),
                                                                                              CRTError.crtError(error))
                                                          }, opCallbackPtr)

        return packetId
    }

    deinit {
        aws_mqtt_client_connection_release(rawValue)
        if let pubCallbackData = pubCallbackData {
            pubCallbackData.deinitializeAndDeallocate()
        }
    }
}
