//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import AwsCIo

public class HttpMessage {
    let rawValue: OpaquePointer
    let allocator: Allocator

    public var headers: HttpHeaders?
    public var body: AwsInputStream? {
        willSet(value) {
            if let newBody = value {
                aws_http_message_set_body_stream(self.rawValue, &newBody.rawValue)
            } else {
                aws_http_message_set_body_stream(self.rawValue, nil)
            }
        }
    }
    // internal initializer. Consumers will initialize HttpRequest subclass and
    // not interact with this class directly.
    init(allocator: Allocator = defaultAllocator) throws {
        self.allocator = allocator;
        self.rawValue = aws_http_message_new_request(allocator.rawValue)
        if self.rawValue == nil {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }

    init(rawValue: OpaquePointer, allocator: Allocator = defaultAllocator) {
        self.rawValue = rawValue
        self.allocator = allocator
    }

    deinit {
        aws_http_message_release(rawValue)
    }
}
//header handling
public extension HttpMessage {

    var headerCount: Int {
           return aws_http_message_get_header_count(rawValue)
    }

    //Todo: what to do in error?
    func addHeaders(headers: HttpHeaders) {
        for index in 0...headers.count {
            let header = headers.get(index: index)
            if let header = header {
                _ = withByteCursorFromStrings(header.name, header.value) { nameCursor, valueCursor in
                    aws_http_headers_add(self.rawValue, nameCursor, valueCursor)
                }
            }
        }
        self.headers = headers
    }

    func removeHeader(atIndex index: Int) -> Bool {
        return aws_http_message_erase_header(rawValue, index) == AWS_OP_SUCCESS
    }

    func getHeader(atIndex index: Int) -> HttpHeader? {
        var header = aws_http_header()
        if aws_http_headers_get_index(self.rawValue, index, &header) == AWS_OP_SUCCESS {
            if let name = header.name.toString(), let value = header.value.toString() {
                return HttpHeader(name: name, value: value)
            }
        }
        return nil
    }

    //Todo: what to do in case of errors?
    func getHeaders() -> [HttpHeader] {
        var headers = [HttpHeader]()
        var header = aws_http_header()
        if headerCount > 0 {
            for index in 0...headerCount - 1 {
                if aws_http_message_get_header(rawValue, &header, index) == AWS_OP_SUCCESS {
                    if let name = header.name.toString(), let value = header.value.toString() {
                        headers.append( HttpHeader(name: name, value: value))
                    }
                }
            }
        }
        return headers
    }
}
