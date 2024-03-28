//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
import AwsCMqtt
@testable import AwsCommonRuntimeKit

func onPublishReceivedCallbackMinimal(_ : PublishReceivedData){
    print("Mqtt5ClientTests: onPublishReceivedCallbackMinimal")
}

func onLifecycleEventStoppedMinimal(_ : LifecycleStoppedData){
    print("Mqtt5ClientTests: onLifecycleEventStoppedMinimal")
}

func onLifecycleEventAttemptingConnectMinimal(_ : LifecycleAttemptingConnectData){
    print("Mqtt5ClientTests: onLifecycleEventAttemptingConnectMinimal")
}

func onLifecycleEventConnectionSuccessMinimal(_ : LifecycleConnectSuccessData){
    print("Mqtt5ClientTests: onLifecycleEventConnectionSuccessMinimal")
}

func onLifecycleEventConnectionFailureMinimal(_ : LifecycleConnectFailureData){
    print("Mqtt5ClientTests: onLifecycleEventConnectionFailureMinimal")
}

func onLifecycleEventDisconnectionMinimal(_ : LifecycleDisconnectData){
    print("Mqtt5ClientTests: onLifecycleEventDisconnectionMinimal")
}


class Mqtt5ClientTests: XCBaseTestCase {

    // [New-UC1] Happy path. Minimal creation and cleanup
    func testMqtt5ClientNewMinimal() throws {
        let elg = try EventLoopGroup()
        let resolver = try HostResolver(eventLoopGroup: elg,
                maxHosts: 8,
                maxTTL: 30)

        let clientBootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: resolver)
        XCTAssertNotNil(clientBootstrap)
        let socketOptions = SocketOptions()
        XCTAssertNotNil(socketOptions)
        let clientOptions = MqttClientOptions(hostName: "localhost", port: 1883, bootstrap: clientBootstrap,
                                   socketOptions: socketOptions);
        XCTAssertNotNil(clientOptions)
        let mqtt5client = try Mqtt5Client(clientOptions: clientOptions);
        XCTAssertNotNil(mqtt5client)

    }

    /*
     * [New-UC2] Maximum creation and cleanup
     */
    func testMqtt5ClientNewFull() throws {
        let elg = try EventLoopGroup()
        let resolver = try HostResolver(eventLoopGroup: elg,
                maxHosts: 8,
                maxTTL: 30)

        let clientBootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: resolver)
        XCTAssertNotNil(clientBootstrap)
        let socketOptions = SocketOptions()
        XCTAssertNotNil(socketOptions)
        let tlsOptions = TLSContextOptions()
        let tlsContext = try TLSContext(options: tlsOptions, mode: .client)
        let will = PublishPacket(qos: QoS.atLeastOnce, topic: "test/Mqtt5_Binding_SWIFT/testMqtt5ClientNewFull",
                                 payload: "will test".data(using: .utf8))
        
        let uuid = UUID().uuidString
        let connectOptions = MqttConnectOptions(
                            keepAliveInterval: 30,
                            clientId: "testMqtt5ClientNewFull_" + uuid,
                            sessionExpiryInterval: 1000,
                            requestResponseInformation: true,
                            requestProblemInformation: true,
                            receiveMaximum: 1000,
                            maximumPacketSize: 1000,
                            willDelayInterval: 1000,
                            will: will,
                            userProperties:   [UserProperty(name: "name1",value: "value1"),
                                             UserProperty(name: "name2",value: "value2"),
                                             UserProperty(name: "name3",value: "value3")])

       
        let clientOptions = MqttClientOptions( hostName: "localhost",
                                            port: 1883,
                                            bootstrap: clientBootstrap,
                                            socketOptions: socketOptions,
                                            tlsCtx: tlsContext,
                                            connectOptions: connectOptions,
                                            sessionBehavior: ClientSessionBehaviorType.clean,
                                            extendedValidationAndFlowControlOptions: ExtendedValidationAndFlowControlOptions.awsIotCoreDefaults,
                                            offlineQueueBehavior: ClientOperationQueueBehaviorType.failAllOnDisconnect,
                                            retryJitterMode: ExponentialBackoffJitterMode.full,
                                            minReconnectDelay: 1000,
                                            maxReconnectDelay: 1000,
                                            minConnectedTimeToResetReconnectDelay: 1000,
                                            pingTimeout: 10,
                                            connackTimeout: 10,
                                            ackTimeout: 60,
                                            topicAliasingOptions: TopicAliasingOptions(),
                                            onPublishReceivedFn: onPublishReceivedCallbackMinimal,
                                            onLifecycleEventStoppedFn: onLifecycleEventStoppedMinimal,
                                            onLifecycleEventAttemptingConnectFn: onLifecycleEventAttemptingConnectMinimal,
                                            onLifecycleEventConnectionFailureFn: onLifecycleEventConnectionFailureMinimal,
                                            onLifecycleEventDisconnectionFn: onLifecycleEventDisconnectionMinimal)
        XCTAssertNotNil(clientOptions)
        let mqtt5client = try Mqtt5Client(clientOptions: clientOptions);
        XCTAssertNotNil(mqtt5client)
    }
}
