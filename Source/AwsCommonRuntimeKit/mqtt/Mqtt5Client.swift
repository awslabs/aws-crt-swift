///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCMqtt
import AwsCIo

public class Mqtt5Client {
    private var rawValue: UnsafeMutablePointer<aws_mqtt5_client>?
    private var callbackCore: MqttCallbackCore

    init(clientOptions options: MqttClientOptions) throws {

        self.callbackCore = MqttCallbackCore(
            onPublishReceivedCallback: options.onPublishReceivedFn,
            onLifecycleEventStoppedCallback: options.onLifecycleEventStoppedFn,
            onLifecycleEventAttemptingConnect: options.onLifecycleEventAttemptingConnectFn,
            onLifecycleEventConnectionSuccess: options.onLifecycleEventConnectionSuccessFn,
            onLifecycleEventConnectionFailure: options.onLifecycleEventConnectionFailureFn,
            onLifecycleEventDisconnection: options.onLifecycleEventDisconnectionFn)

        guard let rawValue = (options.withCPointer(
            userData: self.callbackCore.callbackUserData()) { optionsPointer in
                return aws_mqtt5_client_new(allocator.rawValue, optionsPointer)
            }) else {
            // failed to create client, release the callback core
            self.callbackCore.release()
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    deinit {
        self.callbackCore.close()
        aws_mqtt5_client_release(rawValue)
    }

    public func start() throws {
        if rawValue != nil {
            let errorCode = aws_mqtt5_client_start(rawValue)

            if errorCode != AWS_OP_SUCCESS {
                throw CommonRunTimeError.crtError(CRTError(code: errorCode))
            }
        }
    }

    public func stop(_ disconnectPacket: DisconnectPacket? = nil) throws {
        if rawValue != nil {
            var errorCode: Int32 = 0

            if let disconnectPacket {
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
                let result = aws_mqtt5_client_subscribe(rawValue, subscribePacketPointer, &callbackOptions)
                guard result == AWS_OP_SUCCESS else {
                    continuationCore.release()
                    return continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
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

        return try await withCheckedThrowingContinuation { continuation in

            publishPacket.withCPointer { publishPacketPointer in
                var callbackOptions = aws_mqtt5_publish_completion_options()
                let continuationCore = ContinuationCore<PublishResult>(continuation: continuation)
                callbackOptions.completion_callback = publishCompletionCallback
                callbackOptions.completion_user_data = continuationCore.passRetained()
                let result = aws_mqtt5_client_publish(rawValue, publishPacketPointer, &callbackOptions)
                if result != AWS_OP_SUCCESS {
                    continuationCore.release()
                    return continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
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
                let result = aws_mqtt5_client_unsubscribe(rawValue, unsubscribePacketPointer, &callbackOptions)
                guard result == AWS_OP_SUCCESS else {
                    continuationCore.release()
                    return continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
                }
            }
        }
    }

    public func close() {
        self.callbackCore.close()
        aws_mqtt5_client_release(rawValue)
        rawValue = nil
    }
}

// Operation Completion Callbacks

// The completion callback to invoke when an ack is received in native
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
