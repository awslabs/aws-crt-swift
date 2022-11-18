//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class AWSCredentialsTests: CrtXCBaseTestCase {

    func testCreateAWSCredentials() async throws {
        let accessKey = "AccessKey"
        let secret = "Secret"
        let sessionToken = "Token"
        let expiration = Date(timeIntervalSinceNow: 10)

        let credentials = try AwsCredentials(accessKey: accessKey, secret: secret, sessionToken: sessionToken, expiration: expiration)

        XCTAssertEqual(accessKey, credentials.getAccessKey())
        XCTAssertEqual(secret, credentials.getSecret())
        XCTAssertEqual(sessionToken, credentials.getSessionToken())
        XCTAssertEqual(UInt64(expiration.timeIntervalSince1970), UInt64(credentials.getExpiration().timeIntervalSince1970))
    }

    func testCreateAWSCredentialsWithoutSessionToken() async throws {
        let accessKey = "AccessKey"
        let secret = "Secret"
        let expiration = Date(timeIntervalSinceNow: 10)

        let credentials = try AwsCredentials(accessKey: accessKey, secret: secret, sessionToken: nil, expiration: expiration)

        XCTAssertEqual(accessKey, credentials.getAccessKey())
        XCTAssertEqual(secret, credentials.getSecret())
        XCTAssertEqual(credentials.getSessionToken(), nil)
        XCTAssertEqual(UInt64(expiration.timeIntervalSince1970), UInt64(credentials.getExpiration().timeIntervalSince1970))

    }

    func testCreateAWSCredentialsWithoutAccessKeyThrows() async {
        let accessKey = ""
        let secret = "Secret"
        let expirationTimeout = Date(timeIntervalSinceNow: 10)

        XCTAssertThrowsError(try AwsCredentials(accessKey: accessKey, secret: secret, sessionToken: nil, expiration: expirationTimeout))
    }
}
