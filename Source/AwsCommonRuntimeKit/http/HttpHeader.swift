//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp

public class HttpHeader: CStruct {
    public let name: String
    public let value: String

    public init(name: String,
                value: String) {
        self.name = name
        self.value = value
    }

    init(rawValue: aws_http_header) {
        self.name = rawValue.name.toString()
        self.value = rawValue.value.toString()
    }

    typealias RawType = aws_http_header
    func withCStruct<Result>(_ body: (aws_http_header) -> Result) -> Result {
        var cHeader = aws_http_header()
        return withByteCursorFromStrings(name, value) { nameCursor, valueCursor in
            cHeader.name = nameCursor
            cHeader.value = valueCursor
            return body(cHeader)
        }
    }
}
