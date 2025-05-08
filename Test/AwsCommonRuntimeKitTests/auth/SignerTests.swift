//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest

@testable import AwsCommonRuntimeKit

class SignerTests: XCBaseTestCase {

  let sigv4TestAccessKeyId = "AKIDEXAMPLE"
  let sigv4TestSecretAccessKey = "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY"
  let sigv4TestSessionToken: String? = nil
  let sigv4TestService = "service"
  let sigv4TestRegion = "us-east-1"
  let sigv4TestHost = "example.amazonaws.com"
  let sigv4TestDate = "2015/8/30 12:36"

  func testSigningSigv4Headers() async throws {
    let request = try makeMockRequestWithDoNotSignHeader()
    let provider = try makeMockCredentialsProvider()
    let shouldSignHeader: (String) -> Bool = { name in
      return !name.starts(with: "doNotSign")
    }
    let config = SigningConfig(
      algorithm: SigningAlgorithmType.signingV4,
      signatureType: SignatureType.requestHeaders,
      service: sigv4TestService,
      region: sigv4TestRegion,
      date: getDate(),
      credentialsProvider: provider,
      shouldSignHeader: shouldSignHeader)

    let signedRequest = try await Signer.signRequest(
      request: request,
      config: config)
    XCTAssertNotNil(signedRequest)
    let headers = signedRequest.getHeaders()
    XCTAssert(
      headers.contains(where: {
        $0.name == "Authorization"
          && $0.value.starts(
            with:
              "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature="
          )
      }))
    XCTAssert(headers.contains(where: { $0.name == "X-Amz-Date" }))
    XCTAssert(headers.contains(where: { $0.name == "Host" && $0.value == sigv4TestHost }))
  }

  func testHTTP2SigningSigv4Headers() async throws {
    let request = try makeMockHTTP2RequestWithDoNotSignHeader()
    let provider = try makeMockCredentialsProvider()
    let shouldSignHeader: (String) -> Bool = { name in
      return !name.starts(with: "doNotSign")
    }
    let config = SigningConfig(
      algorithm: SigningAlgorithmType.signingV4,
      signatureType: SignatureType.requestHeaders,
      service: sigv4TestService,
      region: sigv4TestRegion,
      date: getDate(),
      credentialsProvider: provider,
      shouldSignHeader: shouldSignHeader)

    let signedRequest = try await Signer.signRequest(
      request: request,
      config: config)
    XCTAssertNotNil(signedRequest)
    let headers = signedRequest.getHeaders()
    XCTAssert(
      headers.contains(where: {
        $0.name == "Authorization"
          && $0.value.starts(
            with:
              "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=:authority;:method;:path;:scheme;x-amz-date, Signature="
          )
      }))
    XCTAssert(headers.contains(where: { $0.name == "X-Amz-Date" }))
    XCTAssert(headers.contains(where: { $0.name == ":authority" && $0.value == sigv4TestHost }))
  }

  func testSigningSigv4HeadersWithCredentials() async throws {
    let request = try makeMockRequest()
    let credentials = try makeMockCredentials()
    let config = SigningConfig(
      algorithm: SigningAlgorithmType.signingV4,
      signatureType: SignatureType.requestHeaders,
      service: sigv4TestService,
      region: sigv4TestRegion,
      date: getDate(),
      credentials: credentials)

    let signedRequest = try await Signer.signRequest(request: request, config: config)
    XCTAssertNotNil(signedRequest)
    let headers = signedRequest.getHeaders()
    XCTAssert(headers.contains(where: { $0.name == "Authorization" }))
    XCTAssert(headers.contains(where: { $0.name == "X-Amz-Date" }))
    XCTAssert(headers.contains(where: { $0.name == "Host" && $0.value == sigv4TestHost }))
  }

  func testSigningSigv4Body() async throws {
    let request = try makeMockRequestWithBody()
    let credentials = try makeMockCredentials()
    let config = SigningConfig(
      algorithm: SigningAlgorithmType.signingV4,
      signatureType: SignatureType.requestHeaders,
      service: sigv4TestService,
      region: sigv4TestRegion,
      date: getDate(),
      credentials: credentials,
      signedBodyHeader: .contentSha256)

    let signedRequest = try await Signer.signRequest(request: request, config: config)

    XCTAssertNotNil(signedRequest)
    let headers = signedRequest.getHeaders()
    XCTAssert(
      headers.contains(where: {
        $0.name == "Authorization"
          && $0.value.starts(
            with:
              "AWS4-HMAC-SHA256 Credential=wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY/20150830/us-east-1/service/aws4_request, SignedHeaders=content-length;host;x-amz-content-sha256;x-amz-date, Signature="
          )
      }))
    XCTAssert(headers.contains(where: { $0.name == "X-Amz-Date" }))
    XCTAssert(headers.contains(where: { $0.name == "Host" && $0.value == sigv4TestHost }))
    XCTAssert(
      headers.contains(where: {
        $0.name == "x-amz-content-sha256"
          && $0.value == "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
      }))

  }

  func testSigningSigv4AsymmetricHeaders() async throws {
    let request = try makeMockRequest()
    let provider = try makeMockCredentialsProvider()

    let shouldSignHeader: (String) -> Bool = { header in
      return true
    }
    let config = SigningConfig(
      algorithm: .signingV4Asymmetric,
      signatureType: SignatureType.requestHeaders,
      service: sigv4TestService,
      region: sigv4TestRegion,
      date: getDate(),
      credentialsProvider: provider,
      shouldSignHeader: shouldSignHeader)

    let signedRequest = try await Signer.signRequest(request: request, config: config)

    XCTAssertNotNil(signedRequest)
    let headers = signedRequest.getHeaders()
    XCTAssert(
      headers.contains(where: {
        $0.name == "Authorization"
          && $0.value.starts(
            with:
              "AWS4-ECDSA-P256-SHA256 Credential=AKIDEXAMPLE/20150830/service/aws4_request, SignedHeaders=host;x-amz-date;x-amz-region-set, Signature="
          )
      }))
    XCTAssert(headers.contains(where: { $0.name == "X-Amz-Date" }))
    XCTAssert(headers.contains(where: { $0.name == "Host" && $0.value == sigv4TestHost }))
  }

  func testSigningWithCredentialsAndBodyInRequest() async throws {
    let request = try makeMockRequestWithBody()
    let credentials = try makeMockCredentials()
    let config = SigningConfig(
      algorithm: SigningAlgorithmType.signingV4,
      signatureType: SignatureType.requestHeaders,
      service: sigv4TestHost,
      region: sigv4TestRegion,
      credentials: credentials)
    let signedRequest = try await Signer.signRequest(request: request, config: config)
    XCTAssertNotNil(signedRequest)
    let headers = signedRequest.getHeaders()
    XCTAssert(headers.contains(where: { $0.name == "Authorization" }))
  }

  func makeMockRequest() throws -> HTTPRequest {
    let request = try HTTPRequest()
    request.addHeader(header: HTTPHeader(name: "Host", value: sigv4TestHost))
    return request
  }

  func makeMockHTTP2RequestWithDoNotSignHeader() throws -> HTTP2Request {
    let request = try HTTP2Request()
    request.addHeader(header: HTTPHeader(name: ":method", value: "GET"))
    request.addHeader(header: HTTPHeader(name: ":path", value: "/"))
    request.addHeader(header: HTTPHeader(name: ":scheme", value: "https"))
    request.addHeader(header: HTTPHeader(name: ":authority", value: sigv4TestHost))
    request.addHeader(header: HTTPHeader(name: "doNotSign", value: "test-header"))
    return request
  }

  func makeMockRequestWithDoNotSignHeader() throws -> HTTPRequest {
    let request = try HTTPRequest()
    request.addHeader(header: HTTPHeader(name: "Host", value: sigv4TestHost))
    request.addHeader(header: HTTPHeader(name: "doNotSign", value: "test-header"))
    return request
  }

  func makeMockRequestWithBody() throws -> HTTPRequest {
    let request = try HTTPRequest()
    let byteBuffer = ByteBuffer(data: "hello".data(using: .utf8)!)
    request.body = byteBuffer
    request.addHeader(header: HTTPHeader(name: "Host", value: sigv4TestHost))
    request.addHeader(header: HTTPHeader(name: "Content-Length", value: "5"))
    return request
  }

  func makeMockCredentials() throws -> Credentials {
    try Credentials(
      accessKey: sigv4TestSecretAccessKey,
      secret: sigv4TestSecretAccessKey,
      sessionToken: sigv4TestSessionToken)
  }

  func makeMockCredentialsProvider() throws -> CredentialsProvider {
    try CredentialsProvider(
      source: .static(
        accessKey: sigv4TestAccessKeyId,
        secret: sigv4TestSecretAccessKey,
        sessionToken: sigv4TestSessionToken))
  }

  func getDate() -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd HH:mm"
    return formatter.date(from: sigv4TestDate)!
  }
}
