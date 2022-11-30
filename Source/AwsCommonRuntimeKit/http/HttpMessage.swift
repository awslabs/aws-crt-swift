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

    /// Adds a header to the request.
    /// Does nothing if the header name is empty.
    /// - Parameter header: HttpHeader to add
    func addHeader(header: HttpHeader) {
        if header.name.isEmpty {
            return
        }

        guard (header.withCStruct { cHeader in
            aws_http_message_add_header(self.rawValue, cHeader)
        }) == AWS_OP_SUCCESS
        else {
            let error = CRTError.makeFromLastError()
            fatalError("Unable to add header due to error code: \(error.code) message:\(error.message)")
        }
    }

    /// Adds the header array to the request.
    /// Skips element which have empty names.
    /// - Parameter headers: The list of headers to add
    func addHeaders(headers: [HttpHeader]) {
        headers.forEach { addHeader(header: $0) }
    }

    /// Remove all headers with this name
    func removeHeader(name: String) {
        let headers = aws_http_message_get_headers(rawValue)
        _ = name.withByteCursor { nameCursor in
            aws_http_headers_erase(headers, nameCursor)
        }
    }

    /// Set a header value.
    /// The header is added if necessary and any existing values for this name are removed.
    /// Does nothing if the name is empty.
    func setHeader(name: String, value: String) {
        if name.isEmpty {
            return
        }

        let headers = aws_http_message_get_headers(rawValue)
        _ = withByteCursorFromStrings(name, value) { nameCursor, valueCursor in
            aws_http_headers_set(headers, nameCursor, valueCursor)
        }
    }

    /// Get the first value for this name, ignoring any additional values.
    /// Returns nil if no value exits
    /// - Parameter name: The name of header to fetch
    /// - Returns: Returns value of header
    func getHeaderValue(name: String) -> String? {
        let headers = aws_http_message_get_headers(rawValue)
        var value = aws_byte_cursor()

        guard (name.withByteCursor { nameCursor in
            aws_http_headers_get(headers, nameCursor, &value)
        }) == AWS_OP_SUCCESS else {
                return nil
        }
        return value.toString()
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

    /// Removes all headers
    func clearHeaders() {
        aws_http_headers_clear(aws_http_message_get_headers(rawValue))
    }
}
