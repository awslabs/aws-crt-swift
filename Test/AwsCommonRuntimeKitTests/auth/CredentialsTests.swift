//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class CredentialsTests: XCBaseTestCase {

    func testCreateAWSCredentials() async throws {
        let accessKey = "AccessKey"
        let secret = "Secret"
        let sessionToken = "Token"
        let expiration = Date(timeIntervalSinceNow: 10)

        let credentials = try Credentials(accessKey: accessKey, secret: secret, sessionToken: sessionToken, expiration: expiration)

        XCTAssertEqual(accessKey, credentials.getAccessKey())
        XCTAssertEqual(secret, credentials.getSecret())
        XCTAssertEqual(sessionToken, credentials.getSessionToken())
        XCTAssertEqual(UInt64(expiration.timeIntervalSince1970), UInt64(credentials.getExpiration()!.timeIntervalSince1970))

    }
    
    func testCreateAWSCredentialsInfinity() async throws {
        let accessKey = "AccessKey"
        let secret = "Secret"
        let sessionToken = "Token"
        let expiration = Date(timeIntervalSince1970: (Double) (UInt64.max))

        let credentials = try Credentials(accessKey: accessKey, secret: secret, sessionToken: sessionToken, expiration: expiration)

        XCTAssertEqual(accessKey, credentials.getAccessKey())
        XCTAssertEqual(secret, credentials.getSecret())
        XCTAssertEqual(sessionToken, credentials.getSessionToken())
        XCTAssertNil(credentials.getExpiration())

        let expiration2 = Date(timeIntervalSince1970: (Double) (UInt64.max)+10)
        let credentials2 = try Credentials(accessKey: accessKey, secret: secret, sessionToken: sessionToken, expiration: expiration2)
        XCTAssertNil(credentials2.getExpiration())
    }

    func testCreateAWSCredentialsWithoutSessionToken() async throws {
        let accessKey = "AccessKey"
        let secret = "Secret"
        let expiration = Date(timeIntervalSinceNow: 10)

        let credentials = try Credentials(accessKey: accessKey, secret: secret, sessionToken: nil, expiration: expiration)

        XCTAssertEqual(accessKey, credentials.getAccessKey())
        XCTAssertEqual(secret, credentials.getSecret())
        XCTAssertEqual(credentials.getSessionToken(), nil)
        XCTAssertEqual(UInt64(expiration.timeIntervalSince1970), UInt64(credentials.getExpiration()!.timeIntervalSince1970))

    }

    func testCreateAWSCredentialsWithoutExpiration() async throws {
        let accessKey = "AccessKey"
        let secret = "Secret"

        let credentials = try Credentials(accessKey: accessKey, secret: secret, sessionToken: nil)

        XCTAssertEqual(accessKey, credentials.getAccessKey())
        XCTAssertEqual(secret, credentials.getSecret())
        XCTAssertEqual(credentials.getSessionToken(), nil)
        XCTAssertNil(credentials.getExpiration())
    }

    func testCreateAWSCredentialsWithoutAccessKeyThrows() async {
        let accessKey = ""
        let secret = "Secret"
        let expirationTimeout = Date(timeIntervalSinceNow: 10)

        XCTAssertThrowsError(try Credentials(accessKey: accessKey, secret: secret, sessionToken: nil, expiration: expirationTimeout))
    }
}
