//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class SigV4SigningTests: CrtXCBaseTestCase {
    func testCreateSigV4Signer() {
        _ = SigV4HttpRequestSigner(allocator: allocator)
    }
    
    func testSimpleSigning() {
        do {
            let signer = SigV4HttpRequestSigner(allocator: allocator)
            let request = makeMockRequest()
            let credentials = makeMockCredentials()
            let provider = AWSCredentialsProvider(fromEnv: nil, allocator: allocator)
            let config = SigningConfig(credentials: credentials,
                                       credentialsProvider: provider,
                                       expiration: Int64.max,
                                       date: Date(),
                                       service: "service",
                                       region: "test")
            let expectation = XCTestExpectation(description: "Signing complete")
            try signer.signRequest(request: request, config: config) {request,errorCode in
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 3.0)
        }
        catch {
            XCTFail()
        }
    }
    
    func makeMockRequest() -> HttpRequest {
        let request = HttpRequest()
        request.method = "GET"
        request.path = "http://www.test.com/mctest"
        
        let headers = HttpHeaders()
        let headerAdded = headers.add(name: "Host", value: "www.test.com")
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
