//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import AwsCIo

public class HttpMessage {
    let rawValue: OpaquePointer
    let allocator: Allocator

    // Todo: do we need this?
    // public var headers: HttpHeaders?
    public var body: AwsInputStream? {
        willSet(value) {
            if let newBody = value {
                aws_http_message_set_body_stream(self.rawValue, &newBody.awsInputStreamCore.rawValue)
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

    init(headers: HttpHeaders, allocator: Allocator = defaultAllocator) throws {
        self.allocator = allocator
        guard let rawValue = aws_http_message_new_request_with_headers(allocator.rawValue, headers.rawValue) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    deinit {
        aws_http_message_release(rawValue)
    }
}
// header handling
public extension HttpMessage {

    var headerCount: Int {
           return aws_http_message_get_header_count(rawValue)
    }

    // Todo: what to do in error? Maybe refactor it to a better logic?
    func addHeaders(headers: HttpHeaders) {
        for index in 0...headers.count {
            if let header = headers.get(index: index) {
                aws_http_message_add_header(self.rawValue, header)
            }
        }
       // self.headers = headers
    }

    func removeHeader(atIndex index: Int) -> Bool {
        return aws_http_message_erase_header(rawValue, index) == AWS_OP_SUCCESS
    }

    func getHeader(atIndex index: Int) -> HttpHeader? {
        var header = aws_http_header()
        if aws_http_message_get_header(self.rawValue, &header, index) == AWS_OP_SUCCESS {
            return HttpHeader(rawValue: header)
        }
        return nil
    }

    // Todo: what to do in case of errors?
    func getHeaders() -> [HttpHeader] {
        var headers = [HttpHeader]()
        var header = aws_http_header()
        for index in 0 ..< headerCount {
            if aws_http_message_get_header(rawValue, &header, index) == AWS_OP_SUCCESS {
                headers.append(HttpHeader(rawValue: header))
            }
        }
        return headers
    }
}
