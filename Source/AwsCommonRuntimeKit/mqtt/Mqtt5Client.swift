///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCMqtt
import AwsCIo

public class Mqtt5Client {
     private var rawValue: UnsafeMutablePointer<aws_mqtt5_client>?

    init(clientOptions options: MqttClientOptions) throws {
        guard let rawValue = (options.withCPointer { optionsPointer in
                return aws_mqtt5_client_new(allocator.rawValue, optionsPointer)
        })  else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    deinit {
        aws_mqtt5_client_release(rawValue)
    }

    public func close() {
        aws_mqtt5_client_release(rawValue)
        rawValue = nil
    }
}
