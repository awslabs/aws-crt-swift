///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import AwsCIo
import AwsCMqtt
import LibNative

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
public class PublishReceivedData: @unchecked Sendable {

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
public class LifecycleConnectionSuccessData: @unchecked Sendable {

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
public class LifecycleConnectionFailureData: @unchecked Sendable {

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
public class LifecycleDisconnectData: @unchecked Sendable {

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
public typealias OnPublishReceived = @Sendable (PublishReceivedData) -> Void

/// Defines signature of the Lifecycle Event Stopped callback
public typealias OnLifecycleEventStopped = @Sendable (LifecycleStoppedData) -> Void

/// Defines signature of the Lifecycle Event Attempting Connect callback
public typealias OnLifecycleEventAttemptingConnect = @Sendable (LifecycleAttemptingConnectData) ->
    Void

/// Defines signature of the Lifecycle Event Connection Success callback
public typealias OnLifecycleEventConnectionSuccess = @Sendable (LifecycleConnectionSuccessData) ->
    Void

/// Defines signature of the Lifecycle Event Connection Failure callback
public typealias OnLifecycleEventConnectionFailure = @Sendable (LifecycleConnectionFailureData) ->
    Void

/// Defines signature of the Lifecycle Event Disconnection callback
public typealias OnLifecycleEventDisconnection = @Sendable (LifecycleDisconnectData) -> Void

/// Callback for users to invoke upon completion of, presumably asynchronous, OnWebSocketHandshakeIntercept callback's initiated process.
public typealias OnWebSocketHandshakeInterceptComplete = @Sendable (HTTPRequestBase, Int32) -> Void

/// Invoked during websocket handshake to give users opportunity to transform an http request for purposes
/// such as signing/authorization etc... Returning from this function does not continue the websocket
/// handshake since some work flows may be asynchronous. To accommodate that, onComplete must be invoked upon
/// completion of the signing process.
public typealias OnWebSocketHandshakeIntercept = @Sendable (HTTPRequest, @escaping OnWebSocketHandshakeInterceptComplete) -> Void

// MARK: - Mqtt5 Client
public final class Mqtt5Client: Sendable {
    internal let clientCore: Mqtt5ClientCore

    /// Creates a Mqtt5Client instance using the provided MqttClientOptions.
    ///
    /// - Parameters:
    ///     clientOptions: The MqttClientOptions class to use to configure the new Mqtt5Client.
    ///
    /// - Throws: CommonRuntimeError.crtError If the system is unable to allocate space for a native MQTT5 client structure
    public init(clientOptions options: MqttClientOptions) throws {
        clientCore = try Mqtt5ClientCore(clientOptions: options)
    }

    /// Notifies the Mqtt5Client that you want it maintain connectivity to the configured endpoint.
    /// The client will attempt to stay connected using the properties of the reconnect-related parameters
    /// in the Mqtt5Client configuration on client creation.
    ///
    /// - Throws: CommonRuntimeError.crtError
    public func start() throws {
        try self.clientCore.start()
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
        try self.clientCore.stop(disconnectPacket: disconnectPacket)
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
        return try await clientCore.subscribe(subscribePacket: subscribePacket)
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
        return try await clientCore.publish(publishPacket: publishPacket)
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
        return try await clientCore.unsubscribe(unsubscribePacket: unsubscribePacket)
    }

    /// Force the client to discard all operations and cleanup the client.
    public func close() {
        clientCore.close()
    }

    deinit {
        clientCore.close()
    }

}

// MARK: - Internal/Private

// IMPORTANT: You are responsible for concurrency correctness of Mqtt5ClientCore.
// The rawValue is mutable cross threads and protected by the rwlock.
/// Mqtt5 Client Core, internal class to handle Mqtt5 Client operations
internal class Mqtt5ClientCore: @unchecked Sendable {
    // the rawValue is marked as internal to allow rr client to access it
    internal var rawValue: UnsafeMutablePointer<aws_mqtt5_client>?
    fileprivate let rwlock = ReadWriteLock()

    ///////////////////////////////////////
    // user callbacks
    ///////////////////////////////////////
    fileprivate let onPublishReceivedCallback: OnPublishReceived
    fileprivate let onLifecycleEventStoppedCallback: OnLifecycleEventStopped
    fileprivate let onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect
    fileprivate let onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess
    fileprivate let onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure
    fileprivate let onLifecycleEventDisconnection: OnLifecycleEventDisconnection
    // The websocket interceptor could be nil if the websocket is not in use
    fileprivate let onWebsocketInterceptor: OnWebSocketHandshakeIntercept?

    /// Creates a Mqtt5Client instance using the provided MqttClientOptions.
    ///
    /// - Parameters:
    ///     clientOptions: The MqttClientOptions class to use to configure the new Mqtt5Client.
    ///
    /// - Throws: CommonRuntimeError.crtError If the system is unable to allocate space for a native MQTT5 client structure
    init(clientOptions: MqttClientOptions) throws {

        try clientOptions.validateConversionToNative()

        self.onPublishReceivedCallback = clientOptions.onPublishReceivedFn ?? { (_) in }
        self.onLifecycleEventStoppedCallback = clientOptions.onLifecycleEventStoppedFn ?? { (_) in }
        self.onLifecycleEventAttemptingConnect = clientOptions.onLifecycleEventAttemptingConnectFn ?? { (_) in }
        self.onLifecycleEventConnectionSuccess = clientOptions.onLifecycleEventConnectionSuccessFn ?? { (_) in }
        self.onLifecycleEventConnectionFailure = clientOptions.onLifecycleEventConnectionFailureFn ?? { (_) in }
        self.onLifecycleEventDisconnection = clientOptions.onLifecycleEventDisconnectionFn ?? { (_) in }
        self.onWebsocketInterceptor = clientOptions.onWebsocketTransform

        guard let rawValue = (clientOptions.withCPointer(
            userData: Unmanaged<Mqtt5ClientCore>.passRetained(self).toOpaque()) { optionsPointer in
                    return aws_mqtt5_client_new(allocator.rawValue, optionsPointer)
                }) else {
                    // failed to create client, release the callback core
                    Unmanaged<Mqtt5ClientCore>.passUnretained(self).release()
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
            // Validate close() has not been called on client.
            guard let rawValue = self.rawValue else {
                throw CommonRunTimeError.crtError(CRTError(code: AWS_CRT_SWIFT_MQTT_CLIENT_CLOSED.rawValue))
            }
            let errorCode = aws_mqtt5_client_start(rawValue)

            if errorCode != AWS_OP_SUCCESS {
                throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
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
            // Validate close() has not been called on client.
            guard let rawValue = self.rawValue else {
                throw CommonRunTimeError.crtError(CRTError(code: AWS_CRT_SWIFT_MQTT_CLIENT_CLOSED.rawValue))
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
    /// - Throws:
    ///     - CommonRuntimeError.crtError
    public func subscribe(subscribePacket: SubscribePacket) async throws -> SubackPacket {

        return try await withCheckedThrowingContinuation { continuation in
            subscribePacket.withCPointer { subscribePacketPointer in
                var callbackOptions = aws_mqtt5_subscribe_completion_options()
                let continuationCore = ContinuationCore(continuation: continuation)
                callbackOptions.completion_callback = subscribeCompletionCallback
                callbackOptions.completion_user_data = continuationCore.passRetained()
                self.rwlock.read {
                    // Validate close() has not been called on client.
                    guard let rawValue = self.rawValue else {
                        continuationCore.release()
                        return continuation.resume(throwing: CommonRunTimeError.crtError(
                            CRTError(code: AWS_CRT_SWIFT_MQTT_CLIENT_CLOSED.rawValue)))
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
                    // Validate close() has not been called on client.
                    guard let rawValue = self.rawValue else {
                        continuationCore.release()
                        return continuation.resume(throwing: CommonRunTimeError.crtError(
                            CRTError(code: AWS_ERROR_INVALID_ARGUMENT.rawValue, context: "Mqtt client is closed.")))
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
                    // Validate close() has not been called on client.
                    guard let rawValue = self.rawValue else {
                        continuationCore.release()
                        return continuation.resume(throwing: CommonRunTimeError.crtError(
                            CRTError(code: AWS_ERROR_INVALID_ARGUMENT.rawValue, context: "Mqtt client is closed.")))
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

    /// Discard all operations and cleanup the client. It is MANDATORY function to call to release the client core.
    public func close() {
        self.rwlock.write {
            if let rawValue = self.rawValue {
                aws_mqtt5_client_release(rawValue)
                self.rawValue = nil
            }
        }
    }

}

/// Handles lifecycle events from native Mqtt Client
internal func MqttClientHandleLifecycleEvent(_ lifecycleEvent: UnsafePointer<aws_mqtt5_client_lifecycle_event>?) {

    guard let lifecycleEvent: UnsafePointer<aws_mqtt5_client_lifecycle_event> = lifecycleEvent,
        let userData = lifecycleEvent.pointee.user_data else {
        fatalError("MqttClientLifecycleEvents was called from native without an aws_mqtt5_client_lifecycle_event.")
    }
    let clientCore = Unmanaged<Mqtt5ClientCore>.fromOpaque(userData).takeUnretainedValue()
    let crtError = CRTError(code: lifecycleEvent.pointee.error_code)

    // validate the callback flag, if flag is false, return
    clientCore.rwlock.read {
        if clientCore.rawValue == nil { return }

        switch lifecycleEvent.pointee.event_type {
        case AWS_MQTT5_CLET_ATTEMPTING_CONNECT:

            let lifecycleAttemptingConnectData = LifecycleAttemptingConnectData()
            clientCore.onLifecycleEventAttemptingConnect(lifecycleAttemptingConnectData)

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
            clientCore.onLifecycleEventConnectionSuccess(lifecycleConnectionSuccessData)

        case AWS_MQTT5_CLET_CONNECTION_FAILURE:

            var connackPacket: ConnackPacket?
            if let connackView = lifecycleEvent.pointee.connack_data {
                connackPacket = ConnackPacket(connackView)
            }

            let lifecycleConnectionFailureData = LifecycleConnectionFailureData(
                crtError: crtError,
                connackPacket: connackPacket)
            clientCore.onLifecycleEventConnectionFailure(lifecycleConnectionFailureData)

        case AWS_MQTT5_CLET_DISCONNECTION:

            var disconnectPacket: DisconnectPacket?

            if let disconnectView: UnsafePointer<aws_mqtt5_packet_disconnect_view> = lifecycleEvent.pointee.disconnect_data {
                disconnectPacket = DisconnectPacket(disconnectView)
            }

            let lifecycleDisconnectData = LifecycleDisconnectData(
                crtError: crtError,
                disconnectPacket: disconnectPacket)
            clientCore.onLifecycleEventDisconnection(lifecycleDisconnectData)

        case AWS_MQTT5_CLET_STOPPED:
            clientCore.onLifecycleEventStoppedCallback(LifecycleStoppedData())

        default:
            fatalError("A lifecycle event with an invalid event type was encountered.")
        }
    }
}

internal func MqttClientHandlePublishRecieved(
    _ publish: UnsafePointer<aws_mqtt5_packet_publish_view>?,
    _ user_data: UnsafeMutableRawPointer?) {
    let clientCore = Unmanaged<Mqtt5ClientCore>.fromOpaque(user_data!).takeUnretainedValue()

    // validate the callback flag, if flag is false, return
    clientCore.rwlock.read {
        if clientCore.rawValue == nil { return }
        if let publish {
            let publishPacket = PublishPacket(publish)
            let publishReceivedData = PublishReceivedData(publishPacket: publishPacket)
            clientCore.onPublishReceivedCallback(publishReceivedData)
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
    let complete_ctx = SendableRawPointer(pointer: complete_ctx)

    let clientCore = Unmanaged<Mqtt5ClientCore>.fromOpaque(user_data!).takeUnretainedValue()

    // validate the callback flag, if flag is false, return
    clientCore.rwlock.read {
        if clientCore.rawValue == nil { return }

        guard let request else {
            fatalError("Null HttpRequeset in websocket transform function.")
        }
        let httpRequest = HTTPRequest(nativeHttpMessage: request)
        @Sendable func signerTransform(request: HTTPRequestBase, errorCode: Int32) {
            complete_fn?(request.rawValue, errorCode, complete_ctx.pointer)
        }

        if clientCore.onWebsocketInterceptor != nil {
            clientCore.onWebsocketInterceptor!(httpRequest, signerTransform)
        }
    }
}

internal func MqttClientTerminationCallback(_ userData: UnsafeMutableRawPointer?) {
    // Termination callback. This is triggered when the native client is terminated.
    // It is safe to release the swift mqtt5 client at this point.
    // `takeRetainedValue()` would release the client reference. ONLY DO IT AFTER YOU NEED RELEASE THE CLIENT
    _ = Unmanaged<Mqtt5ClientCore>.fromOpaque(userData!).takeRetainedValue()
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
