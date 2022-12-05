//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class ProxyOptionsTests: XCBaseTestCase {

    func testCreateProxyOptions() throws {
        let context = try TLSContext(options: TLSContextOptions(allocator: allocator), mode: TLSMode.client)
        let tlsOptions = TLSConnectionOptions(context: context, allocator: allocator)
        let proxyOptions = HttpProxyOptions(
                hostName: "test",
                port: 80,
                authType: .basic,
                basicAuthUsername: "username",
                basicAuthPassword: "password",
                tlsOptions: tlsOptions)

        proxyOptions.withCStruct { cProxyOptions in
            XCTAssertEqual(cProxyOptions.host.toString(), "test")
            XCTAssertEqual(cProxyOptions.port, 80)
            XCTAssertEqual(cProxyOptions.auth_type, HttpProxyAuthenticationType.basic.rawValue)
            XCTAssertEqual(cProxyOptions.auth_username.toString(), "username")
            XCTAssertEqual(cProxyOptions.auth_password.toString(), "password")
            XCTAssertNotNil(cProxyOptions.tls_options)
        }
    }

}
