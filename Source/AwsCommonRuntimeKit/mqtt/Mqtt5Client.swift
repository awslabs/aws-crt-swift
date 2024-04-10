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

    public func subscribe(subscribePacket: SubscribePacket) async throws -> SubackPacket {

        return try await withCheckedThrowingContinuation { continuation in

            // The completion callback to invoke when an ack is received in native
            func subscribeCompletionCallback(
                subackPacket: UnsafePointer<aws_mqtt5_packet_suback_view>?, errorCode: Int32, userData: UnsafeMutableRawPointer?) {
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

    public func close() {
        self.callbackCore.close()
        aws_mqtt5_client_release(rawValue)
        rawValue = nil
    }
}
