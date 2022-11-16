//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

@available(macOS 12.0, *)
// TODO: improve tests to check header value as well.
class SigV4SigningTests: CrtXCBaseTestCase {
    func testCreateSigV4Signer() {
        _ = SigV4HttpRequestSigner(allocator: allocator)
    }

    func testSimpleSigningWithCredentialsProvider() async throws {
        let signer = SigV4HttpRequestSigner(allocator: allocator)
        let request = try makeMockRequest()
        let provider = try AwsCredentialsProvider.makeStatic(accessKey: "access",
                                                                secret: "key",
                                                                sessionToken: "token",
                                                                allocator: allocator)
        let shouldSignHeader: SigningConfig.ShouldSignHeader = { header in
            return true
        }
        let awsDate = AWSDate(epochS: Date().timeIntervalSince1970)
        let config = SigningConfig(credentialsProvider: provider,
                                   date: awsDate,
                                   service: "service",
                                   region: "us-east-1",
                                   shouldSignHeader: shouldSignHeader,
                                   allocator: allocator)

        let signedRequest = try await signer.signRequest(request: request, config: config)

        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()
        XCTAssert(headers.contains(where: {$0.name == "Authorization"}))
        XCTAssert(headers.contains(where: {$0.name == "X-Amz-Security-Token"}))
    }

    func testSimpleSigningWithCredentials() async throws {
        let signer = SigV4HttpRequestSigner(allocator: allocator)
        let request = try makeMockRequest()
        let credentials = try makeMockCredentials()
        let awsDate = AWSDate(epochS: Date().timeIntervalSince1970)
        let shouldSignHeader: SigningConfig.ShouldSignHeader = { header in
            return true
        }
        let config = SigningConfig(credentials: credentials,
                                   date: awsDate,
                                   service: "service",
                                   region: "us-east-1",
                                   signedBodyValue: .empty,
                                   shouldSignHeader: shouldSignHeader,
                                   allocator: allocator)

        let signedRequest = try await signer.signRequest(request: request, config: config)

        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()
        XCTAssert(headers.contains(where: {$0.name == "Authorization"}))
        XCTAssert(headers.contains(where: {$0.name == "X-Amz-Security-Token"}))
    }

    func testSimpleSigningWithCredentialsAndBodyInRequest() async throws {
        let signer = SigV4HttpRequestSigner(allocator: allocator)
        let request = try makeMockRequestWithBody()
        let credentials = try makeMockCredentials()
        let awsDate = AWSDate(epochS: Date().timeIntervalSince1970)
        let shouldSignHeader: SigningConfig.ShouldSignHeader = { header in
            return true
        }
        let config = SigningConfig(credentials: credentials,
                                   date: awsDate,
                                   service: "service",
                                   region: "us-east-1",
                                   signedBodyValue: .empty,
                                   shouldSignHeader: shouldSignHeader,
                                   allocator: allocator)
        let signedRequest = try await signer.signRequest(request: request, config: config)

        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()
        print(headers)
        XCTAssert(headers.contains(where: {$0.name == "Authorization"}))
        XCTAssert(headers.contains(where: {$0.name == "X-Amz-Security-Token"}))
    }

    func makeMockRequest() throws -> HttpRequest {
        let request = try HttpRequest()
        request.method = "GET"
        request.path = "/"

        let headers = try HttpHeaders()
        let header2Added = headers.add(name: "Host", value: "example.amazonaws.com")
        if header2Added {
            request.addHeaders(headers: headers)
        }

        return request
    }

    func makeMockRequestWithBody() throws -> HttpRequest {
        let request = try HttpRequest()
        request.method = "GET"
        request.path = "/"
        let byteBuffer = ByteBuffer(data: "{}".data(using: .utf8)!)
        request.body = byteBuffer

        let headers = try HttpHeaders()
        let headerAdded = headers.add(name: "Host", value: "example.amazonaws.com")
        if headerAdded {
            request.addHeaders(headers: headers)
        }

        return request
    }

    func makeMockCredentials() throws -> AwsCredentials {
        let credentials = try AwsCredentials(accessKey: "access",
                                      secret: "secret",
                                      sessionToken: "token",
                                      expirationTimeout: UInt64.max,
                                      allocator: allocator)
        return credentials
    }
}
