//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class AWSSignerTests: XCBaseTestCase {

    let SIGV4TEST_ACCESS_KEY_ID = "AKIDEXAMPLE"
    let SIGV4TEST_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY"
    let SIGV4TEST_SESSION_TOKEN: String? = nil
    let SIGV4TEST_SERVICE = "service"
    let SIGV4TEST_REGION = "us-east-1"
    let SIGV4TEST_HOST = "example.amazonaws.com"
    let SIGV4TEST_DATE = "2015/8/30 12:36"

    func testSigningSigv4Headers() async throws {
        let request = try makeMockRequestWithDoNotSignHeader()
        let provider = try makeMockCredentialsProvider()
        let shouldSignHeader: (String) -> Bool = { name in
            return !name.starts(with: "doNotSign")
        }
        let config = AWSSigningConfig(
                algorithm: AWSSigningAlgorithmType.signingV4,
                signatureType: AWSSignatureType.requestHeaders,
                service: SIGV4TEST_SERVICE,
                region: SIGV4TEST_REGION,
                date: getDate(),
                credentialsProvider: provider,
        shouldSignHeader: shouldSignHeader)

        let signedRequest = try await AWSSigner.signRequest(request: request,
                                                                    config: config,
                                                                    allocator: allocator)
        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()
        XCTAssert(headers.contains(where: {
            $0.name == "Authorization"
            && $0.value.starts(with: "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=")
        }))
        XCTAssert(headers.contains(where: { $0.name == "X-Amz-Date" }))
        XCTAssert(headers.contains(where: { $0.name == "Host" && $0.value == SIGV4TEST_HOST }))
    }

    func testSigningSigv4HeadersWithCredentials() async throws {
        let request = try makeMockRequest()
        let credentials = try makeMockCredentials()
        let config = AWSSigningConfig(
                algorithm: AWSSigningAlgorithmType.signingV4,
                signatureType: AWSSignatureType.requestHeaders,
                service: SIGV4TEST_SERVICE,
                region: SIGV4TEST_REGION,
                date: getDate(),
                credentials: credentials)

        let signedRequest = try await AWSSigner.signRequest(request: request,
                                                                    config: config, 
                                                                    allocator: allocator)
        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()
        XCTAssert(headers.contains(where: { $0.name == "Authorization" }))
        XCTAssert(headers.contains(where: { $0.name == "X-Amz-Date" }))
        XCTAssert(headers.contains(where: { $0.name == "Host" && $0.value == SIGV4TEST_HOST }))
    }

    func testSigningSigv4Body() async throws {
        let request = try makeMockRequestWithBody()
        let credentials = try makeMockCredentials()
        let config = AWSSigningConfig(
                algorithm: AWSSigningAlgorithmType.signingV4,
                signatureType: AWSSignatureType.requestHeaders,
                service: SIGV4TEST_SERVICE,
                region: SIGV4TEST_REGION,
                date: getDate(),
                credentials: credentials,
                signedBodyHeader: .contentSha256)

        let signedRequest = try await AWSSigner.signRequest(request: request,
                                                                    config: config, 
                                                                    allocator: allocator)

        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()
        XCTAssert(headers.contains(where: {
            $0.name == "Authorization" && $0.value.starts(with:
            "AWS4-HMAC-SHA256 Credential=wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY/20150830/us-east-1/service/aws4_request, SignedHeaders=content-length;host;x-amz-content-sha256;x-amz-date, Signature=")
        }))
        XCTAssert(headers.contains(where: { $0.name == "X-Amz-Date" }))
        XCTAssert(headers.contains(where: { $0.name == "Host" && $0.value == SIGV4TEST_HOST }))
        XCTAssert(headers.contains(where: { $0.name == "x-amz-content-sha256" && $0.value == "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824" }))

    }

    func testSigningSigv4AsymmetricHeaders() async throws {
        let request = try makeMockRequest()
        let provider = try makeMockCredentialsProvider()

        let shouldSignHeader: (String) -> Bool = { header in
            return true
        }
        let config = AWSSigningConfig(
                algorithm: .signingV4Asymmetric,
                signatureType: AWSSignatureType.requestHeaders,
                service: SIGV4TEST_SERVICE,
                region: SIGV4TEST_REGION,
                date: getDate(),
                credentialsProvider: provider,
                shouldSignHeader: shouldSignHeader)

        let signedRequest = try await AWSSigner.signRequest(request: request,
                                                                    config: config, 
                                                                    allocator: allocator)

        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()
        XCTAssert(headers.contains(where: {
            $0.name == "Authorization" && $0.value.starts(with:
            "AWS4-ECDSA-P256-SHA256 Credential=AKIDEXAMPLE/20150830/service/aws4_request, SignedHeaders=host;x-amz-date;x-amz-region-set, Signature=")
        }))
        XCTAssert(headers.contains(where: { $0.name == "X-Amz-Date" }))
        XCTAssert(headers.contains(where: { $0.name == "Host" && $0.value == SIGV4TEST_HOST }))
    }

    func testSigningWithCredentialsAndBodyInRequest() async throws {
        let request = try makeMockRequestWithBody()
        let credentials = try makeMockCredentials()
        let config = AWSSigningConfig(
                algorithm: AWSSigningAlgorithmType.signingV4,
                signatureType: AWSSignatureType.requestHeaders,
                service: SIGV4TEST_HOST,
                region: SIGV4TEST_REGION,
                credentials: credentials)
        let signedRequest = try await AWSSigner.signRequest(request: request,
                                                                    config: config, 
                                                                    allocator: allocator)
        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()
        XCTAssert(headers.contains(where: { $0.name == "Authorization" }))
    }

    func makeMockRequest() throws -> HTTPRequest {
        let request = try HTTPRequest(allocator: allocator)
        request.addHeader(header: HTTPHeader(name: "Host", value: SIGV4TEST_HOST))
        return request
    }

    func makeMockRequestWithDoNotSignHeader() throws -> HTTPRequest {
        let request = try HTTPRequest()
        request.addHeader(header: HTTPHeader(name: "Host", value: SIGV4TEST_HOST))
        request.addHeader(header: HTTPHeader(name: "doNotSign", value: "test-header"))
        return request
    }

    func makeMockRequestWithBody() throws -> HTTPRequest {
        let request = try HTTPRequest(allocator: allocator)
        let byteBuffer = ByteBuffer(data: "hello".data(using: .utf8)!)
        request.body = byteBuffer
        request.addHeader(header: HTTPHeader(name: "Host", value: SIGV4TEST_HOST))
        request.addHeader(header: HTTPHeader(name: "Content-Length", value: "5"))
        return request
    }

    func makeMockCredentials() throws -> AWSCredentials {
        try AWSCredentials(accessKey: SIGV4TEST_SECRET_ACCESS_KEY,
                secret: SIGV4TEST_SECRET_ACCESS_KEY,
                sessionToken: SIGV4TEST_SESSION_TOKEN,
                allocator: allocator)
    }

    func makeMockCredentialsProvider() throws -> AWSCredentialsProvider {
        try AWSCredentialsProvider(source: .static(accessKey: SIGV4TEST_ACCESS_KEY_ID,
                secret: SIGV4TEST_SECRET_ACCESS_KEY,
                sessionToken: SIGV4TEST_SESSION_TOKEN),
                allocator: allocator)
    }

    func getDate() -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.date(from: SIGV4TEST_DATE)!
    }
}
