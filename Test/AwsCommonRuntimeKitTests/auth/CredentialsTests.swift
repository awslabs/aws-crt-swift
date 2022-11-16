//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class AWSCredentialsTests: CrtXCBaseTestCase {

    func testCreateAWSCredentials() async throws {
        let accessKey = "AccessKey"
        let secret = "Secret"
        let sessionToken = "Token"
        let expirationTimeout: UInt64 = 100

        let credentials = try AwsCredentials(accessKey: accessKey, secret: secret, sessionToken: sessionToken, expirationTimeout: expirationTimeout)

        XCTAssertEqual(accessKey, credentials.getAccessKey())
        XCTAssertEqual(secret, credentials.getSecret())
        XCTAssertEqual(sessionToken, credentials.getSessionToken())
        XCTAssertEqual(expirationTimeout, credentials.getExpirationTimeout())
    }

    func testCreateAWSCredentialsWithoutSessionToken() async throws {
        let accessKey = "AccessKey"
        let secret = "Secret"
        let expirationTimeout: UInt64 = 100

        let credentials = try AwsCredentials(accessKey: accessKey, secret: secret, sessionToken: nil, expirationTimeout: expirationTimeout)

        XCTAssertEqual(accessKey, credentials.getAccessKey())
        XCTAssertEqual(secret, credentials.getSecret())
        XCTAssertEqual(credentials.getSessionToken(), nil)
        XCTAssertEqual(expirationTimeout, credentials.getExpirationTimeout())

    }

    func testCreateAWSCredentialsWithoutAccessKeyThrows() async {
        let accessKey = ""
        let secret = "Secret"
        let expirationTimeout: UInt64 = 100

        XCTAssertThrowsError(try AwsCredentials(accessKey: accessKey, secret: secret, sessionToken: nil, expirationTimeout: expirationTimeout))
    }
}
