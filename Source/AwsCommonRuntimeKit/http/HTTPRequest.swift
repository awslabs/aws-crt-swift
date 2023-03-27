//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import AwsCIo
import AwsCCommon

/// Represents a single client request to be sent on a HTTP 1.1 connection
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
    /// - Throws: CommonRuntimeError
    public init(method: String = "GET",
                path: String = "/",
                headers: [HTTPHeader] = [HTTPHeader](),
                body: IStreamable? = nil) throws {
        guard let rawValue = aws_http_message_new_request(defaultAllocator.rawValue) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        super.init(rawValue: rawValue)

        self.method = method
        self.path = path
        self.body = body
        addHeaders(headers: headers)
    }
}

/// Represents a single client request to be sent on a HTTP2 connection
public class HTTP2Request: HTTPRequestBase {
    /// Creates an http2 request which can be passed to a connection.
    /// - Parameters:
    ///   - headers: (Optional) headers to send
    ///   - body: (Optional) body stream to send as part of request
    /// - Throws: CommonRuntimeError
    public init(headers: [HTTPHeader] = [HTTPHeader](),
                body: IStreamable? = nil) throws {

        guard let rawValue = aws_http2_message_new_request(defaultAllocator.rawValue) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        super.init(rawValue: rawValue)

        self.body = body
        addHeaders(headers: headers)
    }
}
