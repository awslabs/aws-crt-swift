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
                                       date: awsDate,
                                       service: "service",
                                       region: "us-east-1",
                                       shouldSignHeader: shouldSignHeader)
            let expectation = XCTestExpectation(description: "Signing complete")
            let signedRequestResult = try signer.signRequest(request: request, config: config)
            signedRequestResult.then { (futureResult) in
                switch futureResult {
                case.failure(let error):
                    XCTFail(error.localizedDescription)
                case .success(let request):
                    XCTAssertNotNil(request)
                    let headers = request.getHeaders()
                    XCTAssert(headers.contains(where: {$0.name == "Authorization"}))
                    XCTAssert(headers.contains(where: {$0.name == "X-Amz-Security-Token"}))
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
                                       date: awsDate,
                                       service: "service",
                                       region: "us-east-1",
                                       signedBodyValue: .empty,
                                       shouldSignHeader: shouldSignHeader)
            let expectation = XCTestExpectation(description: "Signing complete")
       
            let signedRequestResult = try signer.signRequest(request: request, config: config)
            signedRequestResult.then { (futureResult) in
                switch futureResult {
                case.failure(let error):
                    XCTFail(error.localizedDescription)
                case .success(let request):
                    XCTAssertNotNil(request)
                    let headers = request.getHeaders()
                    XCTAssert(headers.contains(where: {$0.name == "Authorization"}))
                    XCTAssert(headers.contains(where: {$0.name == "X-Amz-Security-Token"}))
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 3.0)
        } catch {
            XCTFail()
        }
    }
    
    func testSimpleSigningWithCredentialsAndBodyInRequest() {
        do {
            let signer = SigV4HttpRequestSigner(allocator: allocator)
            let request = makeMockRequestWithBody()
            let credentials = makeMockCredentials()
            let awsDate = AWSDate(epochS: Date().timeIntervalSince1970)
            let shouldSignHeader: SigningConfig.ShouldSignHeader = { header in
                return true
            }
            let config = SigningConfig(credentials: credentials,
                                       date: awsDate,
                                       service: "service",
                                       region: "us-east-1",
                                       signedBodyValue: .empty,
                                       shouldSignHeader: shouldSignHeader)
            let expectation = XCTestExpectation(description: "Signing complete")
       
            let signedRequestResult = try signer.signRequest(request: request, config: config)
            signedRequestResult.then { (futureResult) in
                switch futureResult {
                case.failure(let error):
                    XCTFail(error.localizedDescription)
                case .success(let request):
                    XCTAssertNotNil(request)
                    let headers = request.getHeaders()
                    XCTAssert(headers.contains(where: {$0.name == "Authorization"}))
                    XCTAssert(headers.contains(where: {$0.name == "X-Amz-Security-Token"}))
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
        request.path = "/"

        let headers = HttpHeaders()
        let header2Added = headers.add(name: "Host", value: "example.amazonaws.com")
        if header2Added {
            request.addHeaders(headers: headers)
        }

        return request
    }
    
    func makeMockRequestWithBody() -> HttpRequest {
        let request = HttpRequest()
        request.method = "GET"
        request.path = "/"
        let byteBuffer = ByteBuffer(data: "{}".data(using: .utf8)!)
        request.body = AwsInputStream(byteBuffer)

        let headers = HttpHeaders()
        let headerAdded = headers.add(name: "Host", value: "example.amazonaws.com")
        if headerAdded {
            request.addHeaders(headers: headers)
        }

        return request
    }

    func makeMockCredentials() -> CRTCredentials {
        let credentials = CRTCredentials(accessKey: "access",
                                      secret: "secret",
                                      sessionToken: "token",
                                      expirationTimeout: UInt64.max,
                                      allocator: allocator)
        return credentials
    }
}
