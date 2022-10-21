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

        let rawValue = proxyOptions.getRawValue()

        XCTAssertNotNil(proxyOptions)
        XCTAssertNotNil(rawValue)

        XCTAssertEqual(proxyOptions.hostName, "test")
        XCTAssertEqual(proxyOptions.port, 80)

        XCTAssertEqual(proxyOptions.authType, authType)
        XCTAssertEqual(rawValue.pointee.auth_type, authType.rawValue)

        XCTAssertEqual(proxyOptions.basicAuthUsername, username)
        username.withByteCursorPointer { usernameCursorPointer in
            XCTAssertTrue(aws_byte_cursor_eq(&rawValue.pointee.auth_username, usernameCursorPointer))
        }

        XCTAssertEqual(proxyOptions.basicAuthPassword, password)
        password.withByteCursorPointer { passwordCursorPointer in
            XCTAssertTrue(aws_byte_cursor_eq(&rawValue.pointee.auth_password, passwordCursorPointer))
        }
    }

    func testProxyOptionsStringOutOfScope() {
        let proxyOptions = HttpProxyOptions(hostName: "test", port: 80)
        do {
            let newHost = "newHost";
            proxyOptions.hostName = newHost;
        }
        let rawValue = proxyOptions.getRawValue()
        XCTAssertNotNil(proxyOptions)
        XCTAssertNotNil(rawValue)

        XCTAssertEqual(proxyOptions.hostName, "newHost")
        "newHost".withByteCursorPointer { passwordCursorPointer in
            XCTAssertTrue(aws_byte_cursor_eq(&rawValue.pointee.host, passwordCursorPointer))
        }
    }

    func testProxyOptionsWithTls() throws {
        let proxyOptions = HttpProxyOptions(hostName: "test", port: 80)
        let context = try TlsContext(options: TlsContextOptions(defaultClientWithAllocator: allocator), mode: TlsMode.client)
        proxyOptions.tlsOptions = TlsConnectionOptions(context, allocator: allocator)

        let rawValue = proxyOptions.getRawValue()
        XCTAssertNotNil(proxyOptions)
        XCTAssertNotNil(rawValue)
        XCTAssertNotNil(proxyOptions.tlsOptions)
        XCTAssertNotNil(rawValue.pointee.tls_options)
    }
}
