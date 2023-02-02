//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class ChunkSignerTests: XCBaseTestCase {

    let accessKey = "AKIAIOSFODNN7EXAMPLE";
    let secret = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY";
    let region = "us-east-1";
    let service = "s3";
    let date = "2013-05-24T00:00:00Z";
    let chunk1Size = 65536;
    let chunk2Size = 1024;
    let url = URL(string: "https://s3.amazonaws.com/examplebucket/chunkObject.txt")!
    let trailingHeaders = [
        HTTPHeader(name: "first", value: "1st"),
        HTTPHeader(name: "second", value: "2nd"),
        HTTPHeader(name: "third", value: "3rd"),
    ]

    let expectedAuthorizationHeader =
            """
            AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request, \
            SignedHeaders=content-encoding;content-length;host;x-amz-content-sha256;x-amz-date;x-amz-decoded-content-length;x-amz-storage-class, \
            Signature=4f232c4386841ef735655705268965c44a0e4690baa4adea153f7db9fa80a0a9
            """
    let expectedRequestSignature = "4f232c4386841ef735655705268965c44a0e4690baa4adea153f7db9fa80a0a9".data(using: .utf8)!
    let expectedFirstChunkSignature = "ad80c730a21e5b8d04586a2213dd63b9a0e99e0e2307b0ade35a65485a288648".data(using: .utf8)!
    let expectedSecondChunkSignature = "0055627c9e194cb4542bae2aa5492e3c1575bbb81b612b7d234b86a503ef5497".data(using: .utf8)!
    let expectedFinalChunkSignature = "b6c6ea8a5354eaf15b3cb7646744f4275b71ea724fed81ceb9323e279d449df9".data(using: .utf8)!
    let expectedTrailerHeaderSignature = "df5735bd9f3295cd9386572292562fefc93ba94e80a0a1ddcbd652c4e0a75e6c".data(using: .utf8)!

    func testChunkedSigv4Signing() async throws {
        let request = makeChunkedRequest()
        let signedRequest = try await Signer.signRequest(
                request: request,
                config: makeChunkedRequestSigningConfig(),
                allocator: allocator)
        XCTAssertNotNil(signedRequest)
        let headers = signedRequest.getHeaders()

        XCTAssert(headers.contains(where: {
            $0.name == "Authorization" && $0.value == expectedAuthorizationHeader
        }))

        let firstChunkSignature = try await Signer.signChunk(
                chunk: Data(repeating: 97, count: chunk1Size),
                previousSignature: expectedRequestSignature,
                config: makeChunkedSigningConfig(),
                allocator: allocator)
        XCTAssertEqual(firstChunkSignature, expectedFirstChunkSignature)

        let secondChunkSignature = try await Signer.signChunk(
                chunk: Data(repeating: 97, count: chunk2Size),
                previousSignature: expectedFirstChunkSignature,
                config: makeChunkedSigningConfig(),
                allocator: allocator)
        XCTAssertEqual(secondChunkSignature, expectedSecondChunkSignature)

        let finalChunkSignature = try await Signer.signChunk(
                chunk: Data(),
                previousSignature: secondChunkSignature,
                config: makeChunkedSigningConfig(),
                allocator: allocator)
        XCTAssertEqual(finalChunkSignature, expectedFinalChunkSignature)

        let trailerChunkSignature = try await Signer.signTrailerHeaders(
                headers: trailingHeaders,
                previousSignature: finalChunkSignature,
                config: makeTrailingSigningConfig(),
                allocator: allocator)
        XCTAssertEqual(trailerChunkSignature, expectedTrailerHeaderSignature)
    }

    func testChunkedSigv4ASigning() async throws {
        let request = makeChunkedRequest()
        let signedRequest = try await Signer.signRequest(request: request, config: makeChunkedRequestSigningConfig(sigv4: false), allocator: allocator)
        // TODO: verify signature
        XCTAssertNotNil(signedRequest)

        let firstChunkSignature = try await Signer.signChunk(
                chunk: Data(repeating: 97, count: chunk1Size),
                previousSignature: expectedRequestSignature,
                config: makeChunkedSigningConfig(sigv4: false),
                allocator: allocator)
        XCTAssertNotNil(firstChunkSignature)

        let secondChunkSignature = try await Signer.signChunk(
                chunk: Data(repeating: 97, count: chunk2Size),
                previousSignature: expectedFirstChunkSignature,
                config: makeChunkedSigningConfig(sigv4: false),
                allocator: allocator)
        XCTAssertNotNil(secondChunkSignature)

        let finalChunk = try await Signer.signChunk(
                chunk: Data(),
                previousSignature: secondChunkSignature,
                config: makeChunkedSigningConfig(sigv4: false),
                allocator: allocator)
        XCTAssertNotNil(finalChunk)
    }

    func makeCredentials() -> Credentials {
        try! Credentials(accessKey: accessKey, secret: secret)
    }

    func makeChunkedRequestSigningConfig(sigv4: Bool = true) -> SigningConfig {
        SigningConfig(
            algorithm: sigv4 ? .signingV4 : .signingV4Asymmetric,
            signatureType: .requestHeaders,
            service: service,
            region: region,
            date: getDate(),
            credentials: makeCredentials(),
            signedBodyHeader: .contentSha256,
            signedBodyValue: sigv4 ? .streamingSha256Payload : .streamingECDSA_P256Sha256Payload,
            useDoubleURIEncode: false)
    }

    func makeChunkedSigningConfig(sigv4: Bool = true) -> SigningConfig {
        SigningConfig(
            algorithm: sigv4 ? .signingV4 : .signingV4Asymmetric,
            signatureType: .requestChunk,
            service: service,
            region: region,
            date: getDate(),
            credentials: makeCredentials(),
            useDoubleURIEncode: false)
    }

    func makeTrailingSigningConfig() -> SigningConfig {
        SigningConfig(
            algorithm: .signingV4,
            signatureType: .requestTrailingHeaders,
            service: service,
            region: region,
            date: getDate(),
            credentials: makeCredentials(),
            useDoubleURIEncode: false)
    }

    func makeChunkedRequest(trailer: Bool = false) -> HTTPRequestBase {
        let request = try! HTTPRequest(method: "PUT", path: url.path, allocator: allocator)
        request.addHeaders(headers: [
            HTTPHeader(name: "Host", value: url.host!),
            HTTPHeader(name: "x-amz-storage-class", value: "REDUCED_REDUNDANCY"),
            HTTPHeader(name: "Content-Encoding", value: "aws-chunked"),
            HTTPHeader(name: "x-amz-decoded-content-length", value: "66560"),
            HTTPHeader(name: "Content-Length", value: "66824"),
        ])
        if trailer {
            request.addHeader(header: HTTPHeader(name: "x-amz-trailer", value: "first,second,third"))
        }
        return request
    }

    func getDate() -> Date {
        let formatter = DateFormatter()

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: date)!
    }
}
