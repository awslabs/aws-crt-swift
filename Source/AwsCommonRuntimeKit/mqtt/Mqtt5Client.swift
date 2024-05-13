///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import AwsCMqtt
import AwsCIo

// MARK: - Callback Data Classes

/// Dataclass containing some simple statistics about the current state of the client's queue of operations
public class ClientOperationStatistics {

    /// Total number of operations submitted to the client that have not yet been completed.  Unacked operations are a subset of this.
    public let incompleteOperationCount: UInt64

    /// Total packet size of operations submitted to the client that have not yet been completed.  Unacked operations are a subset of this.
    public let incompleteOperationSize: UInt64

    /// Total number of operations that have been sent to the server and are waiting for a corresponding ACK before they can be completed.
    public let unackedOperationCount: UInt64

    /// Total packet size of operations that have been sent to the server and are waiting for a corresponding ACK before they can be completed.
    public let unackedOperationSize: UInt64

    public init (incompleteOperationCount: UInt64,
                 incompleteOperationSize: UInt64,
                 unackedOperationCount: UInt64,
                 unackedOperationSize: UInt64) {
        self.incompleteOperationCount = incompleteOperationCount
        self.incompleteOperationSize = incompleteOperationSize
        self.unackedOperationCount = unackedOperationCount
        self.unackedOperationSize = unackedOperationSize
    }
}

/// Class containing data related to a Publish Received Callback
public class PublishReceivedData {

    /// Data model of an `MQTT5 PUBLISH <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901100>`_ packet.
    public let publishPacket: PublishPacket

    public init (publishPacket: PublishPacket) {
        self.publishPacket = publishPacket
    }
}

/// Class containing results of an Stopped Lifecycle Event. Currently unused.
public class LifecycleStoppedData { }

/// Class containing results of an Attempting Connect Lifecycle Event. Currently unused.
public class LifecycleAttemptingConnectData { }

/// Class containing results of a Connect Success Lifecycle Event.
public class LifecycleConnectionSuccessData {

    /// Data model of an `MQTT5 CONNACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901074>`_ packet.
    public let connackPacket: ConnackPacket

    /// Mqtt behavior settings that have been dynamically negotiated as part of the CONNECT/CONNACK exchange.
    public let negotiatedSettings: NegotiatedSettings

    public init (connackPacket: ConnackPacket, negotiatedSettings: NegotiatedSettings) {
        self.connackPacket = connackPacket
        self.negotiatedSettings = negotiatedSettings
    }
}

/// Dataclass containing results of a Connect Failure Lifecycle Event.
public class LifecycleConnectionFailureData {

    /// Error which caused connection failure.
    public let crtError: CRTError

    /// Data model of an `MQTT5 CONNACK <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901074>`_ packet.
    public let connackPacket: ConnackPacket?

    public init (crtError: CRTError, connackPacket: ConnackPacket? = nil) {
        self.crtError = crtError
        self.connackPacket = connackPacket
    }
}

/// Dataclass containing results of a Disconnect Lifecycle Event
public class LifecycleDisconnectData {

    /// Error which caused disconnection.
    public let crtError: CRTError

    /// Data model of an `MQTT5 DISCONNECT <https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901205>`_ packet.
    public let disconnectPacket: DisconnectPacket?

    public init (crtError: CRTError, disconnectPacket: DisconnectPacket? = nil) {
        self.crtError = crtError
        self.disconnectPacket = disconnectPacket
    }
}

// MARK: - Callback typealias definitions

/// Defines signature of the Publish callback
public typealias OnPublishReceived = (PublishReceivedData) async -> Void

/// Defines signature of the Lifecycle Event Stopped callback
public typealias OnLifecycleEventStopped = (LifecycleStoppedData) async -> Void

/// Defines signature of the Lifecycle Event Attempting Connect callback
public typealias OnLifecycleEventAttemptingConnect = (LifecycleAttemptingConnectData) async -> Void

/// Defines signature of the Lifecycle Event Connection Success callback
public typealias OnLifecycleEventConnectionSuccess = (LifecycleConnectionSuccessData) async -> Void

/// Defines signature of the Lifecycle Event Connection Failure callback
public typealias OnLifecycleEventConnectionFailure = (LifecycleConnectionFailureData) async -> Void

/// Defines signature of the Lifecycle Event Disconnection callback
public typealias OnLifecycleEventDisconnection = (LifecycleDisconnectData) async -> Void

/// Callback for users to invoke upon completion of, presumably asynchronous, OnWebSocketHandshakeIntercept callback's initiated process.
public typealias OnWebSocketHandshakeInterceptComplete = (HTTPRequestBase, Int32) -> Void

/// Invoked during websocket handshake to give users opportunity to transform an http request for purposes
/// such as signing/authorization etc... Returning from this function does not continue the websocket
/// handshake since some work flows may be asynchronous. To accommodate that, onComplete must be invoked upon
/// completion of the signing process.
public typealias OnWebSocketHandshakeIntercept = (HTTPRequest, @escaping OnWebSocketHandshakeInterceptComplete) async -> Void

// MARK: - Mqtt5 Client
public class Mqtt5Client {
    private var rawValue: UnsafeMutablePointer<aws_mqtt5_client>?

    ///////////////////////////////////////
    // user callbacks
    ///////////////////////////////////////
    internal let onPublishReceivedCallback: OnPublishReceived
    internal let onLifecycleEventStoppedCallback: OnLifecycleEventStopped
    internal let onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect
    internal let onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess
    internal let onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure
    internal let onLifecycleEventDisconnection: OnLifecycleEventDisconnection
    // The websocket interceptor could be nil if the websocket is not in use
    internal let onWebsocketInterceptor: OnWebSocketHandshakeIntercept?
    internal let rwlock = ReadWriteLock()
    internal var callbackFlag = true

    /// Creates a Mqtt5Client instance using the provided Mqtt5ClientOptions. Once the Mqtt5Client is created,
    /// changing the settings will not cause a change in already created Mqtt5Client's. 
    /// Once created, it is MANDATORY to call `close()` to clean up the Mqtt5Client resource
    ///
    /// - Parameters:
    ///     clientOptions: The MqttClientOptions class to use to configure the new Mqtt5Client.
    ///
    /// - Throws: CommonRuntimeError.crtError If the system is unable to allocate space for a native MQTT5 client structure
    init(clientOptions options: MqttClientOptions) throws {

        try options.validateConversionToNative()

        self.onPublishReceivedCallback = options.onPublishReceivedFn ?? { (_) in return }
        self.onLifecycleEventStoppedCallback = options.onLifecycleEventStoppedFn ?? { (_) in return}
        self.onLifecycleEventAttemptingConnect = options.onLifecycleEventAttemptingConnectFn ?? { (_) in return}
        self.onLifecycleEventConnectionSuccess = options.onLifecycleEventConnectionSuccessFn ?? { (_) in return}
        self.onLifecycleEventConnectionFailure = options.onLifecycleEventConnectionFailureFn ?? { (_) in return}
        self.onLifecycleEventDisconnection = options.onLifecycleEventDisconnectionFn ?? { (_) in return}
        self.onWebsocketInterceptor = options.onWebsocketTransform

        guard let rawValue = (options.withCPointer(
            userData: self.callbackUserData()) { optionsPointer in
                return aws_mqtt5_client_new(allocator.rawValue, optionsPointer)
            }) else {
            // failed to create client, release the callback core
            self.release()
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    /// Notifies the Mqtt5Client that you want it maintain connectivity to the configured endpoint.
    /// The client will attempt to stay connected using the properties of the reconnect-related parameters
    /// in the Mqtt5Client configuration on client creation.
    ///
    /// - Throws: CommonRuntimeError.crtError
    public func start() throws {
        try self.rwlock.read {
            // validate the client in case close() is called.
            guard let rawValue = self.rawValue else {
                // TODO add new error type for client closed
                throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
            }
            let errorCode = aws_mqtt5_client_start(rawValue)

            if errorCode != AWS_OP_SUCCESS {
                throw CommonRunTimeError.crtError(CRTError(code: errorCode))
            }
        }
    }

    /// Notifies the Mqtt5Client that you want it to end connectivity to the configured endpoint, disconnecting any
    /// existing connection and halting any reconnect attempts. No DISCONNECT packets will be sent.
    ///
    /// - Parameters:
    ///     - disconnectPacket: (optional) Properties of a DISCONNECT packet to send as part of the shutdown
    ///     process. When disconnectPacket is null, no DISCONNECT packets will be sent.
    ///
    /// - Throws: CommonRuntimeError.crtError
    public func stop(disconnectPacket: DisconnectPacket? = nil) throws {
        try self.rwlock.read {
            // validate the client in case close() is called.
            guard let rawValue = self.rawValue else {
                throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
            }

            var errorCode: Int32 = 0

            if let disconnectPacket {
                try disconnectPacket.validateConversionToNative()

                disconnectPacket.withCPointer { disconnectPointer in
                    errorCode = aws_mqtt5_client_stop(rawValue, disconnectPointer, nil)
                }
            } else {
                errorCode = aws_mqtt5_client_stop(rawValue, nil, nil)
            }

            if errorCode != AWS_OP_SUCCESS {
                throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
            }
        }
    }

    /// Tells the client to attempt to subscribe to one or more topic filters.
    ///
    /// - Parameters:
    ///     - subscribePacket: SUBSCRIBE packet to send to the server
    /// - Returns:
    ///     - `SubackPacket`: return Suback packet if the subscription operation succeeded
    ///
    /// - Throws: CommonRuntimeError.crtError
    public func subscribe(subscribePacket: SubscribePacket) async throws -> SubackPacket {

        return try await withCheckedThrowingContinuation { continuation in
            subscribePacket.withCPointer { subscribePacketPointer in
                var callbackOptions = aws_mqtt5_subscribe_completion_options()
                let continuationCore = ContinuationCore(continuation: continuation)
                callbackOptions.completion_callback = subscribeCompletionCallback
                callbackOptions.completion_user_data = continuationCore.passRetained()
                self.rwlock.read {
                    // validate the client in case close() is called.
                    guard let rawValue = self.rawValue else {
                        continuationCore.release()
                        return continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
                    }
                    let result = aws_mqtt5_client_subscribe(rawValue, subscribePacketPointer, &callbackOptions)
                    guard result == AWS_OP_SUCCESS else {
                        continuationCore.release()
                        return continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
                    }
                }
            }
        }
    }

    /// Tells the client to attempt to publish to topic filter.
    ///
    /// - Parameters:
    ///     - publishPacket: PUBLISH packet to send to the server
    /// - Returns:
    ///     - For qos 0 packet: return `None` if publish succeeded
    ///     - For qos 1 packet: return `PublishResult` packet if the publish succeeded
    ///
    /// - Throws: CommonRuntimeError.crtError
    public func publish(publishPacket: PublishPacket) async throws -> PublishResult {

        try publishPacket.validateConversionToNative()

        return try await withCheckedThrowingContinuation { continuation in

            publishPacket.withCPointer { publishPacketPointer in
                var callbackOptions = aws_mqtt5_publish_completion_options()
                let continuationCore = ContinuationCore<PublishResult>(continuation: continuation)
                callbackOptions.completion_callback = publishCompletionCallback
                callbackOptions.completion_user_data = continuationCore.passRetained()

                self.rwlock.read {
                    // validate the client in case close() is called.
                    guard let rawValue = self.rawValue else {
                        continuationCore.release()
                        return continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
                    }

                    let result = aws_mqtt5_client_publish(rawValue, publishPacketPointer, &callbackOptions)
                    if result != AWS_OP_SUCCESS {
                        continuationCore.release()
                        return continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
                    }
                }

            }
        }
    }

    /// Tells the client to attempt to unsubscribe to one or more topic filters.
    ///
    /// - Parameters:
    ///     - unsubscribePacket: UNSUBSCRIBE packet to send to the server
    /// - Returns:
    ///     - `UnsubackPacket`: return Unsuback packet if the unsubscribe operation succeeded
    ///
    /// - Throws: CommonRuntimeError.crtError
    public func unsubscribe(unsubscribePacket: UnsubscribePacket) async throws -> UnsubackPacket {

        return try await withCheckedThrowingContinuation { continuation in

            unsubscribePacket.withCPointer { unsubscribePacketPointer in
                var callbackOptions = aws_mqtt5_unsubscribe_completion_options()
                let continuationCore = ContinuationCore(continuation: continuation)
                callbackOptions.completion_callback = unsubscribeCompletionCallback
                callbackOptions.completion_user_data = continuationCore.passRetained()
                self.rwlock.read {
                    // validate the client in case close() is called.
                    guard let rawValue = self.rawValue else {
                        continuationCore.release()
                        return continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
                    }
                    let result = aws_mqtt5_client_unsubscribe(rawValue, unsubscribePacketPointer, &callbackOptions)
                    guard result == AWS_OP_SUCCESS else {
                        continuationCore.release()
                        return continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
                    }
                }
            }
        }
    }

    /// Discard all operations and cleanup the client. It is MANDATORY function to call to release the client.
    public func close() {
        self.rwlock.write {
            self.callbackFlag = false
            aws_mqtt5_client_release(rawValue)
            self.rawValue = nil
        }
    }

    /////////////////////////////////////////////////////////
    // helper functions for self retained reference
    private func callbackUserData() -> UnsafeMutableRawPointer {
        return Unmanaged<Mqtt5Client>.passRetained(self).toOpaque()
    }

    private func release() {
        self.rwlock.write {
            self.callbackFlag = false
        }
        Unmanaged<Mqtt5Client>.passUnretained(self).release()
    }

}

// MARK: - Internal/Private

/// Handles lifecycle events from native Mqtt Client
internal func MqttClientHandleLifecycleEvent(_ lifecycleEvent: UnsafePointer<aws_mqtt5_client_lifecycle_event>?) {

    guard let lifecycleEvent: UnsafePointer<aws_mqtt5_client_lifecycle_event> = lifecycleEvent,
        let userData = lifecycleEvent.pointee.user_data else {
        fatalError("MqttClientLifecycleEvents was called from native without an aws_mqtt5_client_lifecycle_event.")
    }
    let client = Unmanaged<Mqtt5Client>.fromOpaque(userData).takeUnretainedValue()
    let crtError = CRTError(code: lifecycleEvent.pointee.error_code)

    // validate the callback flag, if flag is false, return
    client.rwlock.read {
        if client.callbackFlag == false { return }

        switch lifecycleEvent.pointee.event_type {
        case AWS_MQTT5_CLET_ATTEMPTING_CONNECT:

            let lifecycleAttemptingConnectData = LifecycleAttemptingConnectData()
            Task {
                await client.onLifecycleEventAttemptingConnect(lifecycleAttemptingConnectData)
            }
        case AWS_MQTT5_CLET_CONNECTION_SUCCESS:

            guard let connackView = lifecycleEvent.pointee.connack_data else {
                fatalError("ConnackPacket missing in a Connection Success lifecycle event.")
            }
            let connackPacket = ConnackPacket(connackView)

            guard let negotiatedSettings = lifecycleEvent.pointee.settings else {
                fatalError("NegotiatedSettings missing in a Connection Success lifecycle event.")
            }

            let lifecycleConnectionSuccessData = LifecycleConnectionSuccessData(
                connackPacket: connackPacket,
                negotiatedSettings: NegotiatedSettings(negotiatedSettings))
            Task {
                await client.onLifecycleEventConnectionSuccess(lifecycleConnectionSuccessData)
            }
        case AWS_MQTT5_CLET_CONNECTION_FAILURE:

            var connackPacket: ConnackPacket?
            if let connackView = lifecycleEvent.pointee.connack_data {
                connackPacket = ConnackPacket(connackView)
            }

            let lifecycleConnectionFailureData = LifecycleConnectionFailureData(
                crtError: crtError,
                connackPacket: connackPacket)
            Task {
                await client.onLifecycleEventConnectionFailure(lifecycleConnectionFailureData)
            }
        case AWS_MQTT5_CLET_DISCONNECTION:

            var disconnectPacket: DisconnectPacket?

            if let disconnectView: UnsafePointer<aws_mqtt5_packet_disconnect_view> = lifecycleEvent.pointee.disconnect_data {
                disconnectPacket = DisconnectPacket(disconnectView)
            }

            let lifecycleDisconnectData = LifecycleDisconnectData(
                crtError: crtError,
                disconnectPacket: disconnectPacket)
            Task {
                await client.onLifecycleEventDisconnection(lifecycleDisconnectData)
            }
        case AWS_MQTT5_CLET_STOPPED:
            Task {
                await client.onLifecycleEventStoppedCallback(LifecycleStoppedData())
            }
        default:
            fatalError("A lifecycle event with an invalid event type was encountered.")
        }
    }
}

internal func MqttClientHandlePublishRecieved(
    _ publish: UnsafePointer<aws_mqtt5_packet_publish_view>?,
    _ user_data: UnsafeMutableRawPointer?) {
    let client = Unmanaged<Mqtt5Client>.fromOpaque(user_data!).takeUnretainedValue()

    // validate the callback flag, if flag is false, return
    client.rwlock.read {
        if client.callbackFlag == false { return }
        if let publish {
            let publishPacket = PublishPacket(publish)
            let publishReceivedData = PublishReceivedData(publishPacket: publishPacket)
            Task {
                await client.onPublishReceivedCallback(publishReceivedData)
            }
        } else {
            fatalError("MqttClientHandlePublishRecieved called with null publish")
        }
    }
}

internal func MqttClientWebsocketTransform(
    _ request: OpaquePointer?,
    _ user_data: UnsafeMutableRawPointer?,
    _ complete_fn: (@convention(c) (OpaquePointer?, Int32, UnsafeMutableRawPointer?) -> Void)?,
    _ complete_ctx: UnsafeMutableRawPointer?) {

    let client = Unmanaged<Mqtt5Client>.fromOpaque(user_data!).takeUnretainedValue()

    // validate the callback flag, if flag is false, return
    client.rwlock.read {
        if client.callbackFlag == false { return }

        guard let request else {
            fatalError("Null HttpRequeset in websocket transform function.")
        }
        let httpRequest = HTTPRequest(nativeHttpMessage: request)
        @Sendable func signerTransform(request: HTTPRequestBase, errorCode: Int32) {
            complete_fn?(request.rawValue, errorCode, complete_ctx)
        }

        if client.onWebsocketInterceptor != nil {
            Task {
                await client.onWebsocketInterceptor!(httpRequest, signerTransform)
            }
        }
    }
}

internal func MqttClientTerminationCallback(_ userData: UnsafeMutableRawPointer?) {
    // termination callback
    print("[Mqtt5 Client Swift] TERMINATION CALLBACK")
    // takeRetainedValue would release the reference. ONLY DO IT AFTER YOU DO NOT NEED THE CALLBACK CORE
    _ = Unmanaged<Mqtt5Client>.fromOpaque(userData!).takeRetainedValue()
}

/// The completion callback to invoke when subscribe operation completes in native
private func subscribeCompletionCallback(suback: UnsafePointer<aws_mqtt5_packet_suback_view>?,
                                         error_code: Int32,
                                         complete_ctx: UnsafeMutableRawPointer?) {
    let continuationCore = Unmanaged<ContinuationCore<SubackPacket>>.fromOpaque(complete_ctx!).takeRetainedValue()

    guard error_code == AWS_OP_SUCCESS else {
        return continuationCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: error_code)))
    }

    if let suback {
        continuationCore.continuation.resume(returning: SubackPacket(suback))
    } else {
        fatalError("Suback missing in the subscription completion callback.")
    }
}

/// The completion callback to invoke when publish operation completes in native
private func publishCompletionCallback(packet_type: aws_mqtt5_packet_type,
                                       packet: UnsafeRawPointer?,
                                       error_code: Int32,
                                       complete_ctx: UnsafeMutableRawPointer?) {
    let continuationCore = Unmanaged<ContinuationCore<PublishResult>>.fromOpaque(complete_ctx!).takeRetainedValue()

    if error_code != AWS_OP_SUCCESS {
        return continuationCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: error_code)))
    }

    switch packet_type {
    case AWS_MQTT5_PT_NONE:     // QoS0
        return continuationCore.continuation.resume(returning: PublishResult())

    case AWS_MQTT5_PT_PUBACK:   // QoS1
        guard let puback = packet?.assumingMemoryBound(
            to: aws_mqtt5_packet_puback_view.self) else {
            return continuationCore.continuation.resume(
                throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
            }
        let publishResult = PublishResult(puback: PubackPacket(puback))
        return continuationCore.continuation.resume(returning: publishResult)

    default:
        return continuationCore.continuation.resume(
            throwing: CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_UNKNOWN.rawValue)))
    }
}

/// The completion callback to invoke when unsubscribe operation completes in native
private func unsubscribeCompletionCallback(unsuback: UnsafePointer<aws_mqtt5_packet_unsuback_view>?,
                                           error_code: Int32,
                                           complete_ctx: UnsafeMutableRawPointer?) {
    let continuationCore = Unmanaged<ContinuationCore<UnsubackPacket>>.fromOpaque(complete_ctx!).takeRetainedValue()

    guard error_code == AWS_OP_SUCCESS else {
        return continuationCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: error_code)))
    }

    if let unsuback {
        continuationCore.continuation.resume(returning: UnsubackPacket(unsuback))
    } else {
        fatalError("Unsuback missing in the Unsubscribe completion callback.")
    }
}
