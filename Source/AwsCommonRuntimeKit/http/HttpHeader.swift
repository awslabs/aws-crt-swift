//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp

public struct HttpHeader {
    public var rawValue: aws_http_header
    public var name: String {
        return rawValue.name.toString() ?? ""
        
    }
    public var value: String {
            return rawValue.value.toString() ?? ""
        
    }
    public var compression: HttpHeaderCompression {
        return HttpHeaderCompression(rawValue: rawValue.compression)
    }
    
    init(name: String,
         value: String,
         compression: HttpHeaderCompression = .useCache) {
        self.rawValue = aws_http_header(name: name.awsByteCursor,
                                        value: value.awsByteCursor,
                                        compression: compression.rawValue)
    }
}

