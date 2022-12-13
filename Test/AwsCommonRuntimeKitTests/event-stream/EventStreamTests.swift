//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class EventStreamTests: XCBaseTestCase {
    let semaphore = DispatchSemaphore(value: 0)

    func testEncodeDecodeHeaders() async throws {
        let headers = [
            EventStreamHeader(name: "boolTrue", value: .bool(value: true)),
            EventStreamHeader(name: "boolFalse", value: .bool(value: false)),
            EventStreamHeader(name: "byte", value: .byte(value: 16)),
            EventStreamHeader(name: "int16", value: .int32(value: 16)),
            EventStreamHeader(name: "int32", value: .int32(value: 32)),
            EventStreamHeader(name: "int64", value: .int32(value: 64)),
            EventStreamHeader(name: "byteBuf", value: .byteBuf(value: "data".data(using: .utf8)!)),
            EventStreamHeader(name: "host", value: .string(value: "aws-crt-test-stuff.s3.amazonaws.com")),
            EventStreamHeader(name: "host", value: .string(value: "aws-crt-test-stuff.s3.amazonaws.com")),
            EventStreamHeader(name: "timestamp", value: .timestamp(value: 10)),
            EventStreamHeader(name: "uuid", value: .uuid(value: UUID(uuidString: "63318232-1C63-4D04-9A0C-6907F347704E")!)),
        ]
        let message = try EventStreamMessageEncoder(headers: headers, allocator: allocator)
        let encoded = message.getEncoded()
        var decodedHeaders = [EventStreamHeader]()
        let decoder = EventStreamMessageDecoder(
                onPayloadSegment: { payload, finalSegment in
                    XCTFail("OnPayload callback is triggered unexpectedly.")
                },
                onPreludeReceived: { totalLength, headersLength, crc in
                    XCTAssertEqual(totalLength, 219)
                    XCTAssertEqual(headersLength, 203)
                    XCTAssertEqual(crc, 2544994841)
                },
                onHeaderReceived: { header in
                    decodedHeaders.append(header)
                },
                onError: { code, message in
                    XCTFail("Error occurred. Code: \(code)\nMessage:\(message)")
                })
        try decoder.decode(data: encoded)
        XCTAssertTrue(headers.elementsEqual(decodedHeaders))
    }

    func testEncodeDecodePayload() async throws {
        let payload = "payload".data(using: .utf8)
        let message = try EventStreamMessageEncoder(payload: payload, allocator: allocator)
        let encoded = message.getEncoded()
        var decodedPayload = Data()
        let decoder = EventStreamMessageDecoder(
                onPayloadSegment: { payload, finalSegment in
                    decodedPayload.append(payload)
                },
                onPreludeReceived: { totalLength, headersLength, crc in
                    XCTAssertEqual(totalLength, 23)
                    XCTAssertEqual(headersLength, 0)
                    XCTAssertEqual(crc, 3085079803)
                },
                onHeaderReceived: { header in
                    XCTFail("OnHeader callback is triggered unexpectedly.")
                },
                onError: { code, message in
                    XCTFail("Error occurred. Code: \(code)\nMessage:\(message)")
                })
        try decoder.decode(data: encoded)
        XCTAssertEqual(payload, decodedPayload)
    }

    func testEncodeOutOfScore() async throws {
        let encoded: Data
        do {
            let headers = [EventStreamHeader(name: "int16", value: .int32(value: 16))]
            let payload = "payload".data(using: .utf8)
            let message = try EventStreamMessageEncoder(headers: headers, payload: payload, allocator: allocator)
            encoded = message.getEncoded()
        }

        var decodedPayload = Data()
        var decodedHeaders = [EventStreamHeader]()

        let decoder = EventStreamMessageDecoder(
                onPayloadSegment: { payload, finalSegment in
                    decodedPayload.append(payload)
                },
                onPreludeReceived: { totalLength, headersLength, crc in
                    XCTAssertEqual(totalLength, 34)
                    XCTAssertEqual(headersLength, 11)
                    XCTAssertEqual(crc, 1240562309)
                },
                onHeaderReceived: { header in
                    decodedHeaders.append(header)
                },
                onError: { code, message in
                    XCTFail("Error occurred. Code: \(code)\nMessage:\(message)")
                })
        try decoder.decode(data: encoded)
        XCTAssertEqual("payload".data(using: .utf8), decodedPayload)

        let expectedHeaders = [EventStreamHeader(name: "int16", value: .int32(value: 16))]
        XCTAssertTrue(expectedHeaders.elementsEqual(decodedHeaders))
    }

    func testEmpty() async throws {
        let message = try EventStreamMessageEncoder(allocator: allocator)
        let encoded = message.getEncoded()
        let decoder = EventStreamMessageDecoder(
                onPayloadSegment: { payload, finalSegment in
                    XCTFail("OnPayload callback is triggered unexpectedly.")
                },
                onPreludeReceived: { totalLength, headersLength, crc in
                    XCTAssertEqual(totalLength, 16)
                    XCTAssertEqual(headersLength, 0)
                    XCTAssertEqual(crc, 96618731)
                },
                onHeaderReceived: { header in
                    XCTFail("OnHeader callback is triggered unexpectedly.")
                },
                onError: { code, message in
                    XCTFail("Error occurred. Code: \(code)\nMessage:\(message)")
                })
        try decoder.decode(data: encoded)
    }
}
