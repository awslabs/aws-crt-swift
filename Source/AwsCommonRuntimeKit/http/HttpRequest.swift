//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import AwsCIo
import AwsCCommon

public class HttpRequest: HttpMessage {

    public var method: String {
        get {
            var method = aws_byte_cursor()
            _ = aws_http_message_get_request_method(rawValue, &method)
            return method.toString()
        }
        set {
            newValue.withByteCursor { valueCursor in
                _ = aws_http_message_set_request_method(self.rawValue, valueCursor)
            }
        }
    }

    public var path: String {
        get {
            var path = aws_byte_cursor()
            _ = aws_http_message_get_request_path(rawValue, &path)
            return path.toString()
        }
        set {
            newValue.withByteCursor { valueCursor in
                _ = aws_http_message_set_request_path(self.rawValue, valueCursor)
            }
        }
    }

    /// Creates an http request which can be passed to a connection.
    /// - Parameters:
    ///   - method: Http method to use. Must be a valid http method and not empty.
    ///   - path: Path and query string for Http Request. Must not be empty.
    ///   - headers: (Optional) headers to send
    ///   - body: (Optional) body stream to send as part of request
    ///   - allocator: (Optional) allocator to override
    /// - Throws: CommonRuntimeError
    public init(method: String = "GET",
                path: String = "/",
                headers: [HttpHeader] = [HttpHeader](),
                body: IStreamable? = nil,
                allocator: Allocator = defaultAllocator) throws {
        try super.init(allocator: allocator)

        self.method = method
        self.path = path

        if let body = body {
            let iStreamCore = IStreamCore(iStreamable: body, allocator: allocator)
            aws_http_message_set_body_stream(self.rawValue, &iStreamCore.rawValue)
        }
        addHeaders(headers: headers)
    }
}
