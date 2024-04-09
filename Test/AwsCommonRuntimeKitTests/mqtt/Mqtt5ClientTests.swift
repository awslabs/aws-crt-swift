//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
import AwsCMqtt
@testable import AwsCommonRuntimeKit

class Mqtt5ClientTests: XCBaseTestCase {

    // [New-UC1] Happy path. Minimal creation and cleanup
    func testMqtt5ClientCreationMinimal() throws {
        let elg = try EventLoopGroup()
        let resolver = try HostResolver(eventLoopGroup: elg,
                maxHosts: 8,
                maxTTL: 30)

        let clientBootstrap = try ClientBootstrap(eventLoopGroup: elg,
                hostResolver: resolver)
        XCTAssertNotNil(clientBootstrap)
        let socketOptions = SocketOptions()
        XCTAssertNotNil(socketOptions)
        let clientOptions = MqttClientOptions(hostName: "localhost", port: 443, bootstrap: clientBootstrap,
                                   socketOptions: socketOptions);
        XCTAssertNotNil(clientOptions)
        let mqtt5client = try Mqtt5Client(clientOptions: clientOptions);
        XCTAssertNotNil(mqtt5client)

    }
}
