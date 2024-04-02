///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCMqtt
import AwsCIo

public class Mqtt5Client {
     private var rawValue: UnsafeMutablePointer<aws_mqtt5_client>?
     private let clientOptions: MqttClientOptions

    public init(clientOptions options: MqttClientOptions) throws {
        self.clientOptions = options

        let mqttShutdownCallbackCore = MqttShutdownCallbackCore(
            onPublishReceivedCallback: options.onPublishReceivedFn,
            onLifecycleEventStoppedCallback: options.onLifecycleEventStoppedFn,
            onLifecycleEventAttemptingConnect: options.onLifecycleEventAttemptingConnectFn,
            onLifecycleEventConnectionSuccess: options.onLifecycleEventConnectionSuccessFn,
            onLifecycleEventConnectionFailure: options.onLifecycleEventConnectionFailureFn,
            onLifecycleEventDisconnection: options.onLifecycleEventDisconnectionFn)

        guard let rawValue = (options.withCPointer( userData: mqttShutdownCallbackCore.shutdownCallbackUserData()) { optionsPointer in
                return aws_mqtt5_client_new(allocator.rawValue, optionsPointer)
        })  else {
            // failed to create client, release the callback core
            mqttShutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    deinit {
        aws_mqtt5_client_release(rawValue)
    }

    public func start() {
        // TODO this needs to be checked for whether it returns an error
        aws_mqtt5_client_start(rawValue)
    }

    public func stop() {
        // TODO this needs to be able to take a disconnect packet
        aws_mqtt5_client_stop(rawValue, nil, nil)
    }

    /// TODO: Discard all client operations and force releasing the client. The client could not perform any operation after calling this function.
    public func close() {
        aws_mqtt5_client_release(rawValue)
        rawValue = nil
    }
}
