//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class MqttClientTests: CrtXCBaseTestCase {

    func testMqttClientResourceSafety() throws {
        let options = TlsContextOptions(defaultClientWithAllocator: allocator)
        try options.setAlpnList("")
        let context = try TlsContext(options: options, mode: .client, allocator: allocator)

        let socketOptions = SocketOptions(socketType: .stream)

        let shutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }

        let resolverShutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }

        let elg = EventLoopGroup(allocator: allocator, shutDownOptions: shutDownOptions)
        let resolver = DefaultHostResolver(eventLoopGroup: elg,
                                               maxHosts: 8,
                                               maxTTL: 5,
                                               allocator: allocator,
                                               shutDownOptions: resolverShutDownOptions)

        let clientBootstrapCallbackData = ClientBootstrapCallbackData { sempahore in
            sempahore.signal()
        }

        let clientBootstrap = try ClientBootstrap(eventLoopGroup: elg,
                                                  hostResolver: resolver,
                                                  callbackData: clientBootstrapCallbackData,
                                                  allocator: allocator)

        clientBootstrap.enableBlockingShutdown = true

        let mqttClient = try MqttClient(clientBootstrap: clientBootstrap, allocator: allocator)
        let connectExpectation = XCTestExpectation(description: "connected successfully")

        let connection = mqttClient.newConnection(host: "www.example.com",
                                                  port: 8883,
                                                  socketOptions: socketOptions,
                                                  tlsContext: context,
                                                  useWebSockets: false,
                                                  allocator: allocator)
        connection.onConnectionComplete = { (connection, error, returnCode, retain) in
            connectExpectation.fulfill()
            print("connected")

        }
        let connected = connection.connect(clientId: "testClient",
                                           cleanSession: true,
                                           keepAliveTime: 4000,
                                           requestTimeoutMs: 3000)
        XCTAssertTrue(connected)

        let onMessageSucceeded = connection.setOnMessageHandler { (_, _, _) in }
        XCTAssertTrue(onMessageSucceeded)

        wait(for: [connectExpectation], timeout: 5.0)
    }
}
