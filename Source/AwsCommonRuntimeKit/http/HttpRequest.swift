//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import AwsCIo
import AwsCCommon

public class HttpRequest: HttpMessage {

    public init(method: String = "GET",
                path: String = "/",
                headers: HttpHeaders? = nil,
                body: IStreamable? = nil,
                allocator: Allocator = defaultAllocator) throws {
        if let headers = headers {
            try super.init(headers: headers, allocator: allocator)
        } else {
            try super.init(allocator: allocator)
        }

        guard (method.withByteCursor { methodCursor in
             aws_http_message_set_request_method(self.rawValue, methodCursor)
        }) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        guard (path.withByteCursor { pathCursor in
             aws_http_message_set_request_path(self.rawValue, pathCursor)
        }) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        if let body = body {
            let iStreamCore = IStreamCore(iStreamable: body, allocator: allocator)
            aws_http_message_set_body_stream(self.rawValue, &iStreamCore.rawValue)
        }
    }

    public func getMethod() throws -> String {
        var method = aws_byte_cursor()
        guard aws_http_message_get_request_method(rawValue, &method) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        return method.toString()
    }

    public func setMethod(method: String) throws {
        guard (method.withByteCursor { methodCursor in
            aws_http_message_set_request_method(self.rawValue, methodCursor)
        }) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }

    public func getPath() throws -> String {
        var path = aws_byte_cursor()
        guard aws_http_message_get_request_path(rawValue, &path) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        return path.toString()
    }

    public func setPath(path: String) throws {
        guard (path.withByteCursor { pathCursor in
            aws_http_message_set_request_path(self.rawValue, pathCursor)
        }) == AWS_OP_SUCCESS else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }


}
