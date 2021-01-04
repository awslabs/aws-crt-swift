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
            let staticConfig = MockCredentialsProviderStaticConfigOptions(accessKey: "access",
                                                                          secret: "key",
                                                                          sessionToken: "token")
            let provider = try CRTAWSCredentialsProvider(fromStatic: staticConfig, allocator: allocator)
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
            let signedRequestResult = try signer.signRequest(request: request, config: config)
            signedRequestResult.then { (futureResult) in
                switch futureResult {
                case.failure(let error):
                    XCTFail(error.localizedDescription)
                case .success(let request):
                    XCTAssertNotNil(request)
                }
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
            let shouldSignHeader: SigningConfig.ShouldSignHeader = { header in
                return true
            }
            let config = SigningConfig(credentials: credentials,
                                       expiration: Int64.max,
                                       date: awsDate,
                                       service: "service",
                                       region: "test",
                                       shouldSignHeader: shouldSignHeader,
                                       signatureType: .requestHeaders)
            let expectation = XCTestExpectation(description: "Signing complete")
       
            let signedRequestResult = try signer.signRequest(request: request, config: config)
            signedRequestResult.then { (futureResult) in
                switch futureResult {
                case.failure(let error):
                    XCTFail(error.localizedDescription)
                case .success(let request):
                    XCTAssertNotNil(request)
                }
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

    func makeMockCredentials() -> CRTCredentials {
        let credentials = CRTCredentials(accessKey: "access",
                                      secret: "secret",
                                      sessionToken: "token",
                                      expirationTimeout: Int.max,
                                      allocator: allocator)
        return credentials
    }
}
