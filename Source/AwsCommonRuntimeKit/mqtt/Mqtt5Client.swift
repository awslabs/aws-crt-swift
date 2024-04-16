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
        let errorCode = aws_mqtt5_client_start(rawValue)
        if errorCode != 0 {
            throw CommonRunTimeError.crtError(CRTError(code: errorCode))
        }
    }

    public func stop(disconnectPacket: DisconnectPacket? = nil) throws {
        var errorCode: Int32 = 0

        if let disconnectPacket = disconnectPacket {
            disconnectPacket.withCPointer { disconnectPointer in
                errorCode = aws_mqtt5_client_stop(rawValue, disconnectPointer, nil)
            }
        } else {
            errorCode = aws_mqtt5_client_stop(rawValue, nil, nil)
        }

        if errorCode != 0 {
            throw CommonRunTimeError.crtError(CRTError(code: errorCode))
        }
    }

    /// Tells the client to attempt to subscribe to one or more topic filters.
    ///
    /// - Parameters:
    ///     - subscribePacket: SUBSCRIBE packet to send to the server
    /// - Returns:
    ///     - `SubackPacket`: return Suback packet if the subscription operation succeed otherwise errorCode
    ///
    /// - Throws: CommonRuntimeError.crtError
    public func subscribe(subscribePacket: SubscribePacket) async throws -> SubackPacket {

        return try await withCheckedThrowingContinuation { [weak self]continuation in

            // The completion callback to invoke when an ack is received in native
            func subscribeCompletionCallback(
                subackPacket: UnsafePointer<aws_mqtt5_packet_suback_view>?,
                errorCode: Int32,
                userData: UnsafeMutableRawPointer?) {
                print("[MQTT5 SUBACK TEST] PUBACK RECEIVED")
                let continuationCore = Unmanaged<ContinuationCore<SubackPacket>>.fromOpaque(userData!).takeRetainedValue()

                guard errorCode == AWS_OP_SUCCESS else {
                    return continuationCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
                }

                guard let suback = SubackPacket.convertFromNative(subackPacket)
                else { return continuationCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode))) }

                continuationCore.continuation.resume(returning: suback)

            }

            subscribePacket.withCPointer { subscribePacketPointer in
                var callbackOptions = aws_mqtt5_subscribe_completion_options()
                let continuationCore = ContinuationCore(continuation: continuation)
                callbackOptions.completion_callback = subscribeCompletionCallback
                callbackOptions.completion_user_data = continuationCore.passRetained()
                let result = aws_mqtt5_client_subscribe(self!.rawValue, subscribePacketPointer, &callbackOptions)
                guard result == 0 else {
                    continuationCore.release()
                    return continuation.resume(throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
                }
            }

        }
    }

    /// Tells the client to attempt to subscribe to one or more topic filters.
    ///
    /// - Parameters:
    ///     - publishPacket: PUBLISH packet to send to the server
    /// - Returns:
    ///     - For qos 0 packet: return `None` if publish succeed, otherwise return error code
    ///     - For qos 1 packet: return `PublishResult` packet if the publish succeed, otherwise return error code
    ///
    /// - Throws: CommonRuntimeError.crtError
    public func publish(publishPacket: PublishPacket) async throws -> PublishResult {

        return try await withCheckedThrowingContinuation { continuation in

            // The completion callback to invoke when an ack is received in native
            func publishCompletionCallback(
                packet_type: aws_mqtt5_packet_type,
                navtivePublishResult: UnsafeRawPointer?,
                errorCode: Int32,
                userData: UnsafeMutableRawPointer?) {

                let continuationCore = Unmanaged<ContinuationCore<PublishResult>>.fromOpaque(userData!).takeRetainedValue()

                if errorCode != 0 {
                    continuationCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
                    return
                }

                switch packet_type {
                case AWS_MQTT5_PT_NONE:
                    return continuationCore.continuation.resume(returning: PublishResult())
                case AWS_MQTT5_PT_PUBACK:
                        guard let _publishResult = navtivePublishResult?.assumingMemoryBound(
                            to: aws_mqtt5_packet_puback_view.self) else {
                            return continuationCore.continuation.resume(
                                throwing: CommonRunTimeError.crtError(CRTError.makeFromLastError()))
                        }
                    let publishResult = PublishResult(puback: PubackPacket.convertFromNative(_publishResult))
                    return continuationCore.continuation.resume(returning: publishResult)
                default:
                    return continuationCore.continuation.resume(
                        throwing: CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_UNKNOWN.rawValue)))
                }
            }
            publishPacket.withCPointer { publishPacketPointer in
                var callbackOptions = aws_mqtt5_publish_completion_options()
                callbackOptions.completion_callback = publishCompletionCallback
                callbackOptions.completion_user_data = ContinuationCore<PublishResult>(continuation: continuation).passRetained()
                let result = aws_mqtt5_client_publish(rawValue, publishPacketPointer, &callbackOptions)
                if result != 0 {
                    continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: -1)))
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
