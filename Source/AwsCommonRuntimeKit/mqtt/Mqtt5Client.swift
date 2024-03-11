///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCMqtt

private func MqttClientLifeycyleEvents(_ lifecycleEvent: UnsafePointer<aws_mqtt5_client_lifecycle_event>?) {
    print("[Mqtt5 Client Swift] LIFE CYCLE EVENTS");
}

private func MqttClientPublishRecievedEvents(_ publishPacketView: UnsafePointer<aws_mqtt5_packet_publish_view>?, _ userData: UnsafeMutableRawPointer?) {
    print("[Mqtt5 Client Swift] PUBLISH RECIEVED EVENTS");
}

private func MqttClientTerminationCallback(_ userData: UnsafeMutableRawPointer?)
{
    // termination callback
    print("[Mqtt5 Client Swift] TERMINATION CALLBACK")
}

public class Mqtt5Client{
     private var rawValue: UnsafeMutablePointer<aws_mqtt5_client>
     private let clientOptions: ClientOptions

    init(mqtt5ClientOptions options: ClientOptions){
        self.clientOptions = options;
        
        var raw_options = aws_mqtt5_client_options();
        
        options.hostName.withByteCursor { hostNameByteCursor in
            raw_options.host_name = hostNameByteCursor;
        }
        raw_options.port = 443;
        raw_options.bootstrap = options.bootstrap.rawValue;
        // raw_options.socket_options = options.socketOptions.rawValue;
        // raw_options.tls_options = options.tlsCtx.rawValue;
        raw_options.lifecycle_event_handler = MqttClientLifeycyleEvents;
        raw_options.publish_received_handler = MqttClientPublishRecievedEvents;
        
        var raw_connect_options = aws_mqtt5_packet_connect_view();
        
        raw_connect_options.keep_alive_interval_seconds = 0;
        options.connectOptions?.clientId?.withByteCursor{ clientIdByteCursor in
            raw_connect_options.client_id = clientIdByteCursor;
        }
        options.connectOptions?.username?.withByteCursorPointer{ usernameByteCursor in
            raw_connect_options.username = usernameByteCursor;
        }
        options.connectOptions?.password?.withByteCursorPointer{ passwordByteCursor in
            raw_connect_options.password = passwordByteCursor;
        }
                                                                
        raw_options.connect_options = UnsafePointer(&raw_connect_options);

        raw_options.client_termination_handler = MqttClientTerminationCallback;
        
        self.rawValue = aws_mqtt5_client_new(allocator, &raw_options);
        
        
    }
    
    deinit {
        aws_mqtt5_client_release(rawValue);
    }
}
