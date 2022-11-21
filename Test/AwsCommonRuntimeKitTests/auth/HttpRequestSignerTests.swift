//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class HttpRequestSignerTests: CrtXCBaseTestCase {

    let SIGV4TEST_ACCESS_KEY_ID = "AKIDEXAMPLE"
    let SIGV4TEST_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY"
    let SIGV4TEST_SESSION_TOKEN: String? = nil
    let SIGV4TEST_SERVICE = "service"
    let SIGV4TEST_REGION = "us-east-1"
    let SIGV4TEST_HOST = "example.amazonaws.com"
    let SIGV4TEST_DATE = "2015/8/30 12:36"
    let SIGV4TEST_C_DATE = "20150830T193600Z"

    func testCreateHttpRequestSigner() throws {
        let provider = try makeMockCredentialsProvider()
        _ = HttpRequestSigner(
                algorithm: SigningAlgorithmType.signingV4,
                signatureType: SignatureType.requestHeaders,
                service: SIGV4TEST_SERVICE,
                region: SIGV4TEST_REGION,
                credentialsProvider: provider,
                allocator: allocator)
    }


    func testSigningSigv4Headers() async throws {
        let request = try makeMockRequest()
        let provider = try makeMockCredentialsProvider()

        let signer = HttpRequestSigner(
                algorithm: SigningAlgorithmType.signingV4,
                signatureType: SignatureType.requestHeaders,
                service: SIGV4TEST_SERVICE,
                region: SIGV4TEST_REGION,
                date: getDate(),
                credentialsProvider: provider,
                allocator: allocator)

        let signedRequest = try await signer.signRequest(request: request)

        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()
        XCTAssert(headers.contains(where: {
            $0.name == "Authorization" && $0.value.starts(with:
            "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=")
        }))
        XCTAssert(headers.contains(where: { $0.name == "X-Amz-Date" && $0.value == SIGV4TEST_C_DATE }))
        XCTAssert(headers.contains(where: { $0.name == "Host" && $0.value == SIGV4TEST_HOST }))
    }

    func testSigningSigv4HeadersWithCredentials() async throws {
        let request = try makeMockRequest()
        let credentials = try makeMockCredentials()
        let signer = HttpRequestSigner(
                algorithm: SigningAlgorithmType.signingV4,
                signatureType: SignatureType.requestHeaders,
                service: SIGV4TEST_SERVICE,
                region: SIGV4TEST_REGION,
                date: getDate(),
                credentials: credentials,
                allocator: allocator)

        let signedRequest = try await signer.signRequest(request: request)

        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()
        XCTAssert(headers.contains(where: { $0.name == "Authorization" }))
        XCTAssert(headers.contains(where: { $0.name == "X-Amz-Date" && $0.value == SIGV4TEST_C_DATE }))
        XCTAssert(headers.contains(where: { $0.name == "Host" && $0.value == SIGV4TEST_HOST }))
    }

    func testSigningSigv4Body() async throws {
        let request = try makeMockRequestWithBody()
        let credentials = try makeMockCredentials()
        let signer = HttpRequestSigner(
                algorithm: SigningAlgorithmType.signingV4,
                signatureType: SignatureType.requestHeaders,
                service: SIGV4TEST_SERVICE,
                region: SIGV4TEST_REGION,
                date: getDate(),
                credentials: credentials,
                signedBodyHeader: .contentSha256,
                allocator: allocator)

        let signedRequest = try await signer.signRequest(request: request)

        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()
        XCTAssert(headers.contains(where: {
            $0.name == "Authorization" && $0.value.starts(with:
            "AWS4-HMAC-SHA256 Credential=wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY/20150830/us-east-1/service/aws4_request, SignedHeaders=content-length;host;x-amz-content-sha256;x-amz-date, Signature=")
        }))
        XCTAssert(headers.contains(where: { $0.name == "X-Amz-Date" && $0.value == SIGV4TEST_C_DATE }))
        XCTAssert(headers.contains(where: { $0.name == "Host" && $0.value == SIGV4TEST_HOST }))
        XCTAssert(headers.contains(where: { $0.name == "x-amz-content-sha256" && $0.value == "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824" }))

    }

    func testSigningSigv4AsymmetricHeaders() async throws {
        let request = try makeMockRequest()
        let provider = try makeMockCredentialsProvider()

        let shouldSignHeader: (String) -> Bool = { header in
            return true
        }
        let signer = HttpRequestSigner(
                algorithm: .signingV4Asymmetric,
                signatureType: SignatureType.requestHeaders,
                service: SIGV4TEST_SERVICE,
                region: SIGV4TEST_REGION,
                date: getDate(),
                credentialsProvider: provider,
                shouldSignHeader: shouldSignHeader,
                allocator: allocator)

        let signedRequest = try await signer.signRequest(request: request)

        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()
        XCTAssert(headers.contains(where: {
            $0.name == "Authorization" && $0.value.starts(with:
            "AWS4-ECDSA-P256-SHA256 Credential=AKIDEXAMPLE/20150830/service/aws4_request, SignedHeaders=host;x-amz-date;x-amz-region-set, Signature=")
        }))
        XCTAssert(headers.contains(where: { $0.name == "X-Amz-Date" && $0.value == SIGV4TEST_C_DATE }))
        XCTAssert(headers.contains(where: { $0.name == "Host" && $0.value == SIGV4TEST_HOST }))
    }

    func testSigningWithCredentialsAndBodyInRequest() async throws {
        let request = try makeMockRequestWithBody()
        let credentials = try makeMockCredentials()
        let signer = HttpRequestSigner(
                algorithm: SigningAlgorithmType.signingV4,
                signatureType: SignatureType.requestHeaders,
                service: SIGV4TEST_HOST,
                region: SIGV4TEST_REGION,
                credentials: credentials,
                allocator: allocator)
        let signedRequest = try await signer.signRequest(request: request)

        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()
        XCTAssert(headers.contains(where: { $0.name == "Authorization" }))
    }

    func makeMockRequest() throws -> HttpRequest {
        let request = try HttpRequest()
        request.method = "GET"
        request.path = "/"

        let headers = try HttpHeaders()
        XCTAssertTrue(headers.add(name: "Host", value: SIGV4TEST_HOST))
        request.addHeaders(headers: headers)

        return request
    }

    func makeMockRequestWithBody() throws -> HttpRequest {
        let request = try HttpRequest()
        request.method = "GET"
        request.path = "/"
        let byteBuffer = ByteBuffer(data: "hello".data(using: .utf8)!)
        request.body = byteBuffer

        let headers = try HttpHeaders()
        XCTAssertTrue(headers.add(name: "Host", value: SIGV4TEST_HOST))
        XCTAssertTrue(headers.add(name: "Content-Length", value: "5"))
        request.addHeaders(headers: headers)

        return request
    }

    func makeMockCredentials() throws -> AwsCredentials {
        try AwsCredentials(accessKey: SIGV4TEST_SECRET_ACCESS_KEY,
                secret: SIGV4TEST_SECRET_ACCESS_KEY,
                sessionToken: SIGV4TEST_SESSION_TOKEN,
                allocator: allocator)
    }

    func makeMockCredentialsProvider() throws -> AwsCredentialsProvider {
        try AwsCredentialsProvider(source: .static(accessKey: SIGV4TEST_ACCESS_KEY_ID,
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
