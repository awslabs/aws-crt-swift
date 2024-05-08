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

    deinit {
        print("[MQTT5 CLIENT TEST] DEINIT")
    }

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
                self.rwlock.read{
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
                self.rwlock.read{
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


    public func close() {
        self.rwlock.write{
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
        self.rwlock.write{
            self.callbackFlag = false
        }
        Unmanaged<Mqtt5Client>.passUnretained(self).release()
    }

}

// MARK: - Internal/Private

/// Handles lifecycle events from native Mqtt Client
internal func MqttClientLifeycyleEvents(_ lifecycleEvent: UnsafePointer<aws_mqtt5_client_lifecycle_event>?) {

    guard let lifecycleEvent: UnsafePointer<aws_mqtt5_client_lifecycle_event> = lifecycleEvent else {
        fatalError("MqttClientLifecycleEvents was called from native without an aws_mqtt5_client_lifecycle_event.")
    }

    let crtError = CRTError(code: lifecycleEvent.pointee.error_code)

    if let userData = lifecycleEvent.pointee.user_data {
        let client: Mqtt5Client = Unmanaged<Mqtt5Client>.fromOpaque(userData).takeUnretainedValue()

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

                guard let connackPacket = ConnackPacket.convertFromNative(lifecycleEvent.pointee.connack_data) else {
                    fatalError("ConnackPacket missing in a Connection Success lifecycle event.")
                }

                guard let negotiatedSettings = NegotiatedSettings.convertFromNative(lifecycleEvent.pointee.settings) else {
                    fatalError("NegotiatedSettings missing in a Connection Success lifecycle event.")
                }

                let lifecycleConnectionSuccessData = LifecycleConnectionSuccessData(
                    connackPacket: connackPacket,
                    negotiatedSettings: negotiatedSettings)
                Task {
                    await client.onLifecycleEventConnectionSuccess(lifecycleConnectionSuccessData)
                }
            case AWS_MQTT5_CLET_CONNECTION_FAILURE:

                let connackPacket = ConnackPacket.convertFromNative(lifecycleEvent.pointee.connack_data)

                let lifecycleConnectionFailureData = LifecycleConnectionFailureData(
                    crtError: crtError,
                    connackPacket: connackPacket)
                Task {
                    await client.onLifecycleEventConnectionFailure(lifecycleConnectionFailureData)
                }

            case AWS_MQTT5_CLET_DISCONNECTION:

                guard let disconnectPacket = DisconnectPacket.convertFromNative(lifecycleEvent.pointee.disconnect_data) else {
                    let lifecycleDisconnectData = LifecycleDisconnectData(crtError: crtError)
                    Task {
                        await client.onLifecycleEventDisconnection(lifecycleDisconnectData)
                    }
                    return
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
}

internal func MqttClientPublishRecievedEvents(
    _ publishPacketView: UnsafePointer<aws_mqtt5_packet_publish_view>?,
    _ userData: UnsafeMutableRawPointer?) {
    let client = Unmanaged<Mqtt5Client>.fromOpaque(userData!).takeUnretainedValue()

    // validate the callback flag, if flag is false, return
    client.rwlock.read {
        if client.callbackFlag == false { return }

        guard let publish_packet = PublishPacket.convertFromNative(publishPacketView) else {
            fatalError("NegotiatedSettings missing in a Connection Success lifecycle event.")
        }
        let puback = PublishReceivedData(publishPacket: publish_packet)
        Task {
            await client.onPublishReceivedCallback(puback)
        }
    }
}

internal func MqttClientWebsocketTransform(
    _ rawHttpMessage: OpaquePointer?,
    _ userData: UnsafeMutableRawPointer?,
    _ completeFn: (@convention(c) (OpaquePointer?, Int32, UnsafeMutableRawPointer?) -> Void)?,
    _ completeCtx: UnsafeMutableRawPointer?) {

    let client = Unmanaged<Mqtt5Client>.fromOpaque(userData!).takeUnretainedValue()

    // validate the callback flag, if flag is false, return
        client.rwlock.read {
        if client.callbackFlag == false { return }

        guard let rawHttpMessage else {
            fatalError("Null HttpRequeset in websocket transform function.")
        }
        let httpRequest = HTTPRequest(nativeHttpMessage: rawHttpMessage)
        @Sendable func signerTransform(request: HTTPRequestBase, errorCode: Int32) {
            completeFn?(request.rawValue, errorCode, completeCtx)
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
private func subscribeCompletionCallback(subackPacket: UnsafePointer<aws_mqtt5_packet_suback_view>?,
                                         errorCode: Int32,
                                         userData: UnsafeMutableRawPointer?) {
    let continuationCore = Unmanaged<ContinuationCore<SubackPacket>>.fromOpaque(userData!).takeRetainedValue()

    guard errorCode == AWS_OP_SUCCESS else {
        return continuationCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
    }

    guard let suback = SubackPacket.convertFromNative(subackPacket) else {
        fatalError("Suback missing in the subscription completion callback.")
    }

    continuationCore.continuation.resume(returning: suback)
}

/// The completion callback to invoke when publish operation completes in native
private func publishCompletionCallback(packet_type: aws_mqtt5_packet_type,
                                       navtivePublishResult: UnsafeRawPointer?,
                                       errorCode: Int32,
                                       userData: UnsafeMutableRawPointer?) {
    let continuationCore = Unmanaged<ContinuationCore<PublishResult>>.fromOpaque(userData!).takeRetainedValue()

    if errorCode != AWS_OP_SUCCESS {
        return continuationCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
    }

    switch packet_type {
    case AWS_MQTT5_PT_NONE:     // QoS0
        return continuationCore.continuation.resume(returning: PublishResult())
    case AWS_MQTT5_PT_PUBACK:   // QoS1
        guard let puback = navtivePublishResult?.assumingMemoryBound(
            to: aws_mqtt5_packet_puback_view.self) else {
            return continuationCore.continuation.resume(
                throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
            }
        let publishResult = PublishResult(puback: PubackPacket.convertFromNative(puback))
        return continuationCore.continuation.resume(returning: publishResult)
    default:
        return continuationCore.continuation.resume(
            throwing: CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_UNKNOWN.rawValue)))
    }
}

/// The completion callback to invoke when unsubscribe operation completes in native
private func unsubscribeCompletionCallback(unsubackPacket: UnsafePointer<aws_mqtt5_packet_unsuback_view>?,
                                           errorCode: Int32,
                                           userData: UnsafeMutableRawPointer?) {
    let continuationCore = Unmanaged<ContinuationCore<UnsubackPacket>>.fromOpaque(userData!).takeRetainedValue()

    guard errorCode == AWS_OP_SUCCESS else {
        return continuationCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
    }

    guard let unsuback = UnsubackPacket.convertFromNative(unsubackPacket) else {
        fatalError("Unsuback missing in the Unsubscribe completion callback.")
    }

    continuationCore.continuation.resume(returning: unsuback)
}
