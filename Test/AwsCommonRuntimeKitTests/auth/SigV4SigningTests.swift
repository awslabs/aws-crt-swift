//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AwsCommonRuntimeKit
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest

@available(macOS 12.0, *)
class SigV4SigningTests: CrtXCBaseTestCase {
    func testCreateSigV4Signer() {
        _ = SigV4HttpRequestSigner(allocator: allocator)
    }

    func testSimpleSigningWithCredentialsProvider() async throws {
        let signer = SigV4HttpRequestSigner(allocator: allocator)
        let request = makeMockRequest()
        let staticConfig = MockCredentialsProviderStaticConfigOptions(accessKey: "access",
                                                                      secret: "key",
                                                                      sessionToken: "token")
        let provider = try CRTAWSCredentialsProvider(fromStatic: staticConfig, allocator: allocator)
        let shouldSignHeader: SigningConfig.ShouldSignHeader = { _ in
            true
        }
        let awsDate = AWSDate(epochS: Date().timeIntervalSince1970)
        let config = SigningConfig(credentialsProvider: provider,
                                   date: awsDate,
                                   service: "service",
                                   region: "us-east-1",
                                   shouldSignHeader: shouldSignHeader)

        let signedRequest = try await signer.signRequest(request: request, config: config)

        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()
        XCTAssert(headers.contains(where: { $0.name == "Authorization" }))
        XCTAssert(headers.contains(where: { $0.name == "X-Amz-Security-Token" }))
    }

    func testSimpleSigningWithCredentials() async throws {
        let signer = SigV4HttpRequestSigner(allocator: allocator)
        let request = makeMockRequest()
        let credentials = makeMockCredentials()
        let awsDate = AWSDate(epochS: Date().timeIntervalSince1970)
        let shouldSignHeader: SigningConfig.ShouldSignHeader = { _ in
            true
        }
        let config = SigningConfig(credentials: credentials,
                                   date: awsDate,
                                   service: "service",
                                   region: "us-east-1",
                                   signedBodyValue: .empty,
                                   shouldSignHeader: shouldSignHeader)

        let signedRequest = try await signer.signRequest(request: request, config: config)

        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()
        XCTAssert(headers.contains(where: { $0.name == "Authorization" }))
        XCTAssert(headers.contains(where: { $0.name == "X-Amz-Security-Token" }))
    }

    func testSimpleSigningWithCredentialsAndBodyInRequest() async throws {
        let signer = SigV4HttpRequestSigner(allocator: allocator)
        let request = makeMockRequestWithBody()
        let credentials = makeMockCredentials()
        let awsDate = AWSDate(epochS: Date().timeIntervalSince1970)
        let shouldSignHeader: SigningConfig.ShouldSignHeader = { _ in
            true
        }
        let config = SigningConfig(credentials: credentials,
                                   date: awsDate,
                                   service: "service",
                                   region: "us-east-1",
                                   signedBodyValue: .empty,
                                   shouldSignHeader: shouldSignHeader)

        let signedRequest = try await signer.signRequest(request: request, config: config)

        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()
        XCTAssert(headers.contains(where: { $0.name == "Authorization" }))
        XCTAssert(headers.contains(where: { $0.name == "X-Amz-Security-Token" }))
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
