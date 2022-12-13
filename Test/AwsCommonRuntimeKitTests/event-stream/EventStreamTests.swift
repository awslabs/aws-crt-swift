//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class EventStreamTests: XCBaseTestCase {
    let semaphore = DispatchSemaphore(value: 0)

    func testEncodeDecodeHeaders() async throws {
        do {
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
            var receivedHeaders = [EventStreamHeader]()
            let decoder = EventStreamMessageDecoder(
                    onPayloadSegment: { payload, finalSegment in
                        print("on payload")
                    },
                    onPreludeReceived: { totalLength, headersLength, crc in
                        print("prelude")
                    },
                    onHeaderReceived: { header in
                        receivedHeaders.append(header)
                    },
                    onError: { code, message in
                        print("error")
                    })
            try decoder.decode(data: encoded)
            XCTAssertTrue(headers.elementsEqual(receivedHeaders))
        } catch let error {
            print(error)
        }
    }

}
