//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import AwsCCommon
@testable import AwsCommonRuntimeKit

class ProxyOptionsTests: CrtXCBaseTestCase {

    func testCreateProxyOptions() throws {
        let proxyOptions = HttpProxyOptions(hostName: "test", port: 80)
        let username = "testName"
        proxyOptions.basicAuthUsername = username
        let password = "password"
        proxyOptions.basicAuthPassword = password
        let authType = HttpProxyAuthenticationType.basic
        proxyOptions.authType = authType

        XCTAssertNotNil(proxyOptions)
        XCTAssertEqual(proxyOptions.hostName, "test")
        XCTAssertEqual(proxyOptions.port, 80)
        XCTAssertEqual(proxyOptions.authType, authType)
        XCTAssertEqual(proxyOptions.basicAuthUsername, username)
        XCTAssertEqual(proxyOptions.basicAuthPassword, password)

        HttpProxyOptions.withCPointer(proxyOptions: proxyOptions) { proxyOptionsPointer in
            XCTAssertNotNil(proxyOptionsPointer)
            XCTAssertEqual(proxyOptionsPointer?.pointee.auth_type, authType.rawValue)
            username.withByteCursorPointer { usernameCursorPointer in
                var cUserName = proxyOptionsPointer!.pointee.auth_username
                XCTAssertTrue(aws_byte_cursor_eq(&cUserName, usernameCursorPointer))
            }
            password.withByteCursorPointer { passwordCursorPointer in
                var cPassword = proxyOptionsPointer!.pointee.auth_password
                XCTAssertTrue(aws_byte_cursor_eq(&cPassword, passwordCursorPointer))
            }
        }
    }

    func testProxyOptionsStringOutOfScope() {
        let proxyOptions = HttpProxyOptions(hostName: "test", port: 80)
        do {
            let newHost = "newHost";
            proxyOptions.hostName = newHost;
        }
        XCTAssertNotNil(proxyOptions)
        XCTAssertEqual(proxyOptions.hostName, "newHost")
        HttpProxyOptions.withCPointer(proxyOptions: proxyOptions) { proxyOptionsPointer in
            XCTAssertNotNil(proxyOptionsPointer)
            "newHost".withByteCursorPointer { hostCursorPointer in
                var cHost = proxyOptionsPointer!.pointee.host
                XCTAssertTrue(aws_byte_cursor_eq(&cHost, hostCursorPointer))
            }
        }
    }

    func testProxyOptionsWithTls() throws {
        let proxyOptions = HttpProxyOptions(hostName: "test", port: 80)
        let context = try TlsContext(options: TlsContextOptions(defaultClientWithAllocator: allocator), mode: TlsMode.client)
        proxyOptions.tlsOptions = TlsConnectionOptions(context, allocator: allocator)

        XCTAssertNotNil(proxyOptions)
        XCTAssertNotNil(proxyOptions.tlsOptions)
        HttpProxyOptions.withCPointer(proxyOptions: proxyOptions) { proxyOptionsPointer in
            XCTAssertNotNil(proxyOptionsPointer)
            XCTAssertNotNil(proxyOptionsPointer?.pointee.tls_options)
        }
    }
}
