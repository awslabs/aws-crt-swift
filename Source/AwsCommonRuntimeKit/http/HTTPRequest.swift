//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import AwsCIo
import AwsCCommon

public class HTTPRequest: HTTPRequestBase {

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
                headers: [HTTPHeader] = [HTTPHeader](),
                body: IStreamable? = nil,
                allocator: Allocator = defaultAllocator) throws {
        guard let rawValue = aws_http_message_new_request(allocator.rawValue) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        super.init(rawValue: rawValue, allocator: allocator)

        self.method = method
        self.path = path

        if let body = body {
            let iStreamCore = IStreamCore(iStreamable: body, allocator: allocator)
            aws_http_message_set_body_stream(self.rawValue, &iStreamCore.rawValue)
        }
        addHeaders(headers: headers)
    }
}

public class HTTP2Request: HTTPRequestBase {
    let manualDataWrites: Bool
    /// Creates an http2 request which can be passed to a connection.
    /// - Parameters:
    ///   - headers: (Optional) headers to send
    ///   - body: (Optional) body stream to send as part of request
    ///   - manualDataWrites: Set it to true to indicate body data will be provided over time.
    ///                       The data can be be supplied via `HTTP2Stream.writeData`.
    ///                       The last data should be sent with endOfStream as true to complete the stream.
    ///   - allocator: (Optional) allocator to override
    /// - Throws: CommonRuntimeError
    public init(headers: [HTTPHeader] = [HTTPHeader](),
                body: IStreamable? = nil,
                manualDataWrites: Bool = false,
                allocator: Allocator = defaultAllocator) throws {
        self.manualDataWrites = manualDataWrites

        guard let rawValue = aws_http2_message_new_request(allocator.rawValue) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        super.init(rawValue: rawValue, allocator: allocator)

        if let body = body {
            let iStreamCore = IStreamCore(iStreamable: body, allocator: allocator)
            aws_http_message_set_body_stream(self.rawValue, &iStreamCore.rawValue)
        }
        addHeaders(headers: headers)
    }
}


