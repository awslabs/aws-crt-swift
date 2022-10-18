//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
import AwsCCommon
@testable import AwsCommonRuntimeKit

class ProxyOptionsTests: CrtXCBaseTestCase {

    func testCreateProxyOptions() throws {
        let proxyOptions = HttpProxyOptions(hostName: "test", port: 80)
        XCTAssertNotNil(proxyOptions)

        XCTAssertEqual(proxyOptions.hostName, "test")
        XCTAssertEqual(proxyOptions.port, 80)
        let authType = HttpProxyAuthenticationType.basic

        proxyOptions.authType = authType
        XCTAssertEqual(proxyOptions.authType, authType)
        XCTAssertEqual(proxyOptions.rawValue.pointee.auth_type, authType.rawValue)

        let username = "testName"
        proxyOptions.basicAuthUsername = username
        XCTAssertEqual(proxyOptions.basicAuthUsername, username)
        username.withByteCursorPointer { usernameCursorPointer in
            XCTAssertTrue(aws_byte_cursor_eq(&proxyOptions.rawValue.pointee.auth_username, usernameCursorPointer))
        }

        let password = "password"
        proxyOptions.basicAuthPassword = password
        XCTAssertEqual(proxyOptions.basicAuthPassword, password)
        password.withByteCursorPointer { passwordCursorPointer in
            XCTAssertTrue(aws_byte_cursor_eq(&proxyOptions.rawValue.pointee.auth_password, passwordCursorPointer))
        }
    }

    func testProxyOptionsStringOutOfScope() {
        let proxyOptions = HttpProxyOptions(hostName: "test", port: 80)
        XCTAssertNotNil(proxyOptions)

        do {
            let newHost = "newHost";
            proxyOptions.hostName = newHost;
        }
        XCTAssertEqual(proxyOptions.hostName, "newHost")
        "newHost".withByteCursorPointer { passwordCursorPointer in
            XCTAssertTrue(aws_byte_cursor_eq(&proxyOptions.rawValue.pointee.host, passwordCursorPointer))
        }
    }

    func testProxyOptionsWithTls() throws {
        let proxyOptions = HttpProxyOptions(hostName: "test", port: 80)
        XCTAssertNotNil(proxyOptions)
        let context = try TlsContext(options: TlsContextOptions(defaultClientWithAllocator: allocator), mode: TlsMode.client)
        proxyOptions.tlsOptions = TlsConnectionOptions(context, allocator: allocator)
        XCTAssertNotNil(proxyOptions.tlsOptions)
        XCTAssertNotNil(proxyOptions.rawValue.pointee.tls_options)
    }
}
