//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp

public struct HttpHeader {
    public var rawValue: aws_http_header
    public var name: String {
        rawValue.name.toString() ?? ""
    }

    public var value: String {
        rawValue.value.toString() ?? ""
    }

    public var compression: HttpHeaderCompression {
        HttpHeaderCompression(rawValue: rawValue.compression)
    }

    init(name: String,
         value: String,
         compression: HttpHeaderCompression = .useCache)
    {
        rawValue = aws_http_header(name: name.awsByteCursor,
                                   value: value.awsByteCursor,
                                   compression: compression.rawValue)
    }
}
