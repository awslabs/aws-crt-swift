//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class SigV4SigningTests: CrtXCBaseTestCase {
    func testCreateSigV4Signer() {
        _ = SigV4HttpRequestSigner(allocator: allocator)
    }

    func testSimpleSigningWithCredentialsProvider() {
        do {
            let signer = SigV4HttpRequestSigner(allocator: allocator)
            let request = makeMockRequest()
            let staticConfig = CredentialsProviderStaticConfigOptions(accessKey: "access", secret: "key", sessionToken: "token")
            let provider = try AWSCredentialsProvider(fromStatic: staticConfig, allocator: allocator)
            let shouldSignHeader: SigningConfig.ShouldSignHeader = { header in
                return true
            }
            let awsDate = AWSDate(epochS: Date().timeIntervalSince1970)
            let config = SigningConfig(credentialsProvider: provider,
                                       expiration: Int64.max,
                                       date: awsDate,
                                       service: "service",
                                       region: "test",
                                       shouldSignHeader: shouldSignHeader,
                                       signatureType: .requestHeaders)
            let expectation = XCTestExpectation(description: "Signing complete")
            try signer.signRequest(request: request, config: config) {_, _ in
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 3.0)
        } catch let error {
            print(error)
            XCTFail(error.localizedDescription)
        }
    }

    func testSimpleSigningWithCredentials() {
        do {
            let signer = SigV4HttpRequestSigner(allocator: allocator)
            let request = makeMockRequest()
            let credentials = makeMockCredentials()
            let awsDate = AWSDate(epochS: Date().timeIntervalSince1970)
            let config = SigningConfig(credentials: credentials,
                                       expiration: Int64.max,
                                       date: awsDate,
                                       service: "service",
                                       region: "test")
            let expectation = XCTestExpectation(description: "Signing complete")
            try signer.signRequest(request: request, config: config) {_, _ in
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 3.0)
        } catch {
            XCTFail()
        }
    }

    func makeMockRequest() -> HttpRequest {
        let request = HttpRequest()
        request.method = "GET"
        request.path = "http://www.test.com/mctest"

        let headers = HttpHeaders()
        let headerAdded = headers.add(name: "X-Amz-Security-Token", value: "token")
        if headerAdded {
            request.addHeaders(headers: headers)
        }

        return request
    }

    func makeMockCredentials() -> Credentials {
        let credentials = Credentials(accessKey: "access",
                                      secret: "secret",
                                      sessionToken: "token",
                                      expirationTimeout: Int.max,
                                      allocator: allocator)
        return credentials
    }
}
