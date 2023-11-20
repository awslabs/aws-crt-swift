//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import AwsCEventStream
@testable import AwsCommonRuntimeKit

class EventStreamTests: XCBaseTestCase {
    let semaphore = DispatchSemaphore(value: 0)

    func testEncodeDecodeHeaders() async throws {
        let onCompleteWasCalled = XCTestExpectation(description: "OnComplete was called")

        let headers = [
            EventStreamHeader(name: "bool", value: .bool(value: true)),
            EventStreamHeader(name: "byte", value: .byte(value: 16)),
            EventStreamHeader(name: "int16", value: .int32(value: 16)),
            EventStreamHeader(name: "int32", value: .int32(value: 32)),
            EventStreamHeader(name: "int64", value: .int32(value: 64)),
            EventStreamHeader(name: "byteBuf", value: .byteBuf(value: "data".data(using: .utf8)!)),
            EventStreamHeader(name: "host", value: .string(value: "aws-crt-test-stuff.s3.amazonaws.com")),
            EventStreamHeader(name: "host", value: .string(value: "aws-crt-test-stuff.s3.amazonaws.com")),
            EventStreamHeader(name: "headerWithUtf8Character🧐", value: .string(value: "testValueWithEmoji🤯")),
            EventStreamHeader(name: "bool", value: .bool(value: false)),
            EventStreamHeader(name: "timestamp", value: .timestamp(value: Date(timeIntervalSinceNow: 10))),
            EventStreamHeader(name: "uuid", value: .uuid(value: UUID(uuidString: "63318232-1C63-4D04-9A0C-6907F347704E")!)),
        ]
        let message = EventStreamMessage(headers: headers)
        let encoded = try message.getEncoded()
        var decodedHeaders = [EventStreamHeader]()
        let decoder = EventStreamMessageDecoder(
                onPayloadSegment: { payload, finalSegment in
                    XCTFail("OnPayload callback is triggered unexpectedly.")
                },
                onPreludeReceived: { totalLength, headersLength in
                    XCTAssertEqual(totalLength, 263)
                    XCTAssertEqual(headersLength, 247)
                },
                onHeaderReceived: { header in
                    decodedHeaders.append(header)
                },
                onComplete: {
                    onCompleteWasCalled.fulfill()
                },
                onError: { code, message in
                    XCTFail("Error occurred. Code: \(code)\nMessage:\(message)")
                })
        try decoder.decode(data: encoded)
        XCTAssertTrue(headers.elementsEqual(decodedHeaders))
        wait(for: [onCompleteWasCalled], timeout: 1)
    }

    func testEncodeDecodePayload() async throws {
        let onCompleteWasCalled = XCTestExpectation(description: "OnComplete was called")

        let payload = "payload".data(using: .utf8)!
        let message = EventStreamMessage(payload: payload)
        let encoded = try message.getEncoded()
        var decodedPayload = Data()
        let decoder = EventStreamMessageDecoder(
                onPayloadSegment: { payload, finalSegment in
                    decodedPayload.append(payload)
                },
                onPreludeReceived: { totalLength, headersLength in
                    XCTAssertEqual(totalLength, 23)
                    XCTAssertEqual(headersLength, 0)
                },
                onHeaderReceived: { header in
                    XCTFail("OnHeader callback is triggered unexpectedly.")
                }, onComplete: {
                    onCompleteWasCalled.fulfill()
                },
                onError: { code, message in
                    XCTFail("Error occurred. Code: \(code)\nMessage:\(message)")
                })
        try decoder.decode(data: encoded)
        XCTAssertEqual(payload, decodedPayload)
        wait(for: [onCompleteWasCalled], timeout: 1)
    }

    func testEncodeOutOfScope() async throws {
        let onCompleteWasCalled = XCTestExpectation(description: "OnComplete was called")

        let encoded: Data
        do {
            let headers = [EventStreamHeader(name: "int16", value: .int32(value: 16))]
            let payload = "payload".data(using: .utf8)!
            let message = EventStreamMessage(headers: headers, payload: payload)
            encoded = try message.getEncoded()
        }

        var decodedPayload = Data()
        var decodedHeaders = [EventStreamHeader]()

        let decoder = EventStreamMessageDecoder(
                onPayloadSegment: { payload, finalSegment in
                    decodedPayload.append(payload)
                },
                onPreludeReceived: { totalLength, headersLength in
                    XCTAssertEqual(totalLength, 34)
                    XCTAssertEqual(headersLength, 11)
                },
                onHeaderReceived: { header in
                    decodedHeaders.append(header)
                }, onComplete: {
                    onCompleteWasCalled.fulfill()
                },
                onError: { code, message in
                    XCTFail("Error occurred. Code: \(code)\nMessage:\(message)")
                })
        try decoder.decode(data: encoded)
        XCTAssertEqual("payload".data(using: .utf8), decodedPayload)

        let expectedHeaders = [EventStreamHeader(name: "int16", value: .int32(value: 16))]
        XCTAssertTrue(expectedHeaders.elementsEqual(decodedHeaders))
        wait(for: [onCompleteWasCalled], timeout: 1)
    }

    func testDecodeByteByByte() async throws {
        let onCompleteWasCalled = XCTestExpectation(description: "OnComplete was called")

        let headers = [EventStreamHeader(name: "int16", value: .int32(value: 16))]
        let payload = "payload".data(using: .utf8)!
        let message = EventStreamMessage(headers: headers, payload: payload)
        let encoded = try message.getEncoded()

        var decodedPayload = Data()
        var decodedHeaders = [EventStreamHeader]()

        let decoder = EventStreamMessageDecoder(
                onPayloadSegment: { payload, finalSegment in
                    decodedPayload.append(payload)
                },
                onPreludeReceived: { totalLength, headersLength in
                    XCTAssertEqual(totalLength, 34)
                    XCTAssertEqual(headersLength, 11)
                },
                onHeaderReceived: { header in
                    decodedHeaders.append(header)
                }, onComplete: {
                    onCompleteWasCalled.fulfill()
                },
                onError: { code, message in
                    XCTFail("Error occurred. Code: \(code)\nMessage:\(message)")
                })
        for byte in encoded {
            try decoder.decode(data: Data([byte]))
        }

        XCTAssertEqual(payload, decodedPayload)
        XCTAssertTrue(headers.elementsEqual(decodedHeaders))
        wait(for: [onCompleteWasCalled], timeout: 1)
    }

    func testEmpty() async throws {
        let onCompleteWasCalled = XCTestExpectation(description: "OnComplete was called")

        let message = EventStreamMessage()
        let encoded = try message.getEncoded()
        let decoder = EventStreamMessageDecoder(
                onPayloadSegment: { payload, finalSegment in
                    XCTFail("OnPayload callback is triggered unexpectedly.")
                },
                onPreludeReceived: { totalLength, headersLength in
                    XCTAssertEqual(totalLength, 16)
                    XCTAssertEqual(headersLength, 0)
                },
                onHeaderReceived: { header in
                    XCTFail("OnHeader callback is triggered unexpectedly.")
                }, onComplete: {
                    onCompleteWasCalled.fulfill()
                },
                onError: { code, message in
                    XCTFail("Error occurred. Code: \(code)\nMessage:\(message)")
                })
        try decoder.decode(data: encoded)
        wait(for: [onCompleteWasCalled], timeout: 1)
    }
}
