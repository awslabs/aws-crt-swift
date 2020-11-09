//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import AwsCIo

public class HttpMessage {
    let rawValue: OpaquePointer
    private let owned: Bool

    public var body: AwsInputStream? {
        willSet(value) {
            if let newBody = value {
                aws_http_message_set_body_stream(self.rawValue, &newBody.rawValue)
            } else {
                aws_http_message_set_body_stream(self.rawValue, nil)
            }
        }
    }

    init(owningMessage message: OpaquePointer) {
        self.owned = true
        self.rawValue = message
    }

    init(borrowingMessage message: OpaquePointer) {
        self.owned = false
        self.rawValue = message
    }

    deinit {
        if let oldStream = aws_http_message_get_body_stream(self.rawValue) {
            aws_input_stream_destroy(oldStream)
        }
        if self.owned {
            aws_http_message_destroy(self.rawValue)
        }
    }
}
//header handling
public extension HttpMessage {
    var headerCount: Int {
           return aws_http_message_get_header_count(rawValue)
    }

    var headers: [HttpHeader] {
        var headers = [HttpHeader]()
        for index in 0...headerCount {
            if let header = getHeader(atIndex: index) {
                headers.append(header)
            } else {
                continue
            }
        }
        return headers
    }

    func addHeaders(headers: HttpHeaders) {
        for index in 0...headers.count {
            var header = HttpHeader(name: "", value: "")
            if aws_http_headers_get_index(headers.rawValue, index, &header.rawValue) == AWS_OP_SUCCESS {
                aws_http_message_add_header(rawValue, header.rawValue)
            } else {
                continue
            }
        }
    }

    func removeHeader(atIndex index: Int) -> Bool {
        if aws_http_message_erase_header(rawValue, index) != AWS_OP_SUCCESS {
            return false
        }

        return true
    }

    func getHeader(atIndex index: Int) -> HttpHeader? {
        var header = HttpHeader(name: "", value: "")
        if aws_http_message_get_header(rawValue, &header.rawValue, index) != AWS_OP_SUCCESS {
            return nil
        }
        return header
    }
}
