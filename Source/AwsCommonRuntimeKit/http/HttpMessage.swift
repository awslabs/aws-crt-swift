//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp
import AwsCIo

public class HttpMessage {
    let rawValue: OpaquePointer
    let allocator: Allocator

    public var body: IStreamable? {
        willSet(value) {
            if let newBody = value {
                let iStreamCore = IStreamCore(iStreamable: newBody, allocator: allocator)
                aws_http_message_set_body_stream(self.rawValue, &iStreamCore.rawValue)
            } else {
                aws_http_message_set_body_stream(self.rawValue, nil)
            }
        }
    }

    // internal initializer. Consumers will initialize HttpRequest subclass and

    // not interact with this class directly.
    init(allocator: Allocator = defaultAllocator) throws {
        self.allocator = allocator
        guard let rawValue = aws_http_message_new_request(allocator.rawValue) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    deinit {
        aws_http_message_release(rawValue)
    }
}

public extension HttpMessage {

    var headerCount: Int {
        return aws_http_message_get_header_count(rawValue)
    }

    func addHeader(header: HttpHeader) throws {
        guard (header.withCStruct { cHeader in
            aws_http_message_add_header(self.rawValue, cHeader)
        }) == AWS_OP_SUCCESS
        else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }

    func addHeaders(headers: [HttpHeader]) throws {
        try headers.forEach {
            try addHeader(header: $0)
        }
    }

    /// Get header at index. Index must be valid.
    func removeHeader(at index: Int) {
        guard aws_http_message_erase_header(rawValue, index) == AWS_OP_SUCCESS else {
            fatalError("Index out of range")
        }
    }

    /// Get header at index. Index must be valid.
    func getHeader(at index: Int) -> HttpHeader {
        var header = aws_http_header()
        guard aws_http_message_get_header(self.rawValue, &header, index) == AWS_OP_SUCCESS else {
            fatalError("Index out of range")
        }
        return HttpHeader(rawValue: header)
    }

    func getHeaders() -> [HttpHeader] {
        var headers = [HttpHeader]()
        var header = aws_http_header()
        for index in 0..<headerCount {
            if aws_http_message_get_header(rawValue, &header, index) == AWS_OP_SUCCESS {
                headers.append(HttpHeader(rawValue: header))
            } else {
                fatalError("Index is invalid")
            }
        }
        return headers
    }
}
