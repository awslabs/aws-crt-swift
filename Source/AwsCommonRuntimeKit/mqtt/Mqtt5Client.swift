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

        return try await withCheckedThrowingContinuation { continuation in

            // The completion callback to invoke when an ack is received in native
            func subscribeCompletionCallback(
                subackPacket: UnsafePointer<aws_mqtt5_packet_suback_view>?,
                errorCode: Int32,
                userData: UnsafeMutableRawPointer?) {
                let continuationCore = Unmanaged<ContinuationCore<SubackPacket>>.fromOpaque(userData!).takeRetainedValue()
                if errorCode == 0 {
                    guard let suback = SubackPacket.convertFromNative(subackPacket)
                    else { fatalError("Suback missing in the subscription completion callback.") }

                    continuationCore.continuation.resume(returning: suback)
                } else {
                    continuationCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
                }
            }

            subscribePacket.withCPointer { subscribePacketPointer in
                var callbackOptions = aws_mqtt5_subscribe_completion_options()
                callbackOptions.completion_callback = subscribeCompletionCallback
                callbackOptions.completion_user_data = ContinuationCore(continuation: continuation).passRetained()
                let result = aws_mqtt5_client_subscribe(rawValue, subscribePacketPointer, &callbackOptions)
                if result != 0 {
                    continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: -1)))
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
    public func publish(publishPacket: PublishPacket) async throws -> PublishResult{

        return try await withCheckedThrowingContinuation { continuation in

            // The completion callback to invoke when an ack is received in native
            func publishCompletionCallback(
                packet_type : aws_mqtt5_packet_type,
                publishResult: UnsafeRawPointer?,
                errorCode: Int32,
                userData: UnsafeMutableRawPointer?) {

                let continuationCore = Unmanaged<ContinuationCore<PublishResult>>.fromOpaque(userData!).takeRetainedValue()

                if (errorCode != 0 ){
                    continuationCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
                    return
                }


                var returnedPublishResult : PublishResult?

                switch packet_type{
                    case AWS_MQTT5_PT_NONE:
                        break
                    case AWS_MQTT5_PT_PUBACK:
                            let _publishResult = publishResult?.assumingMemoryBound(to: aws_mqtt5_packet_puback_view.self)
                            returnedPublishResult = PublishResult(puback: PubackPacket.convertFromNative(_publishResult))
                    default:
                        continuationCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_UNKNOWN.rawValue)))
                        return
                }

                continuationCore.continuation.resume(returning: returnedPublishResult!)
                return
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
