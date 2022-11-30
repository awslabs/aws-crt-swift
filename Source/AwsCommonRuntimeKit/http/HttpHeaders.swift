////  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
////  SPDX-License-Identifier: Apache-2.0.
//import AwsCHttp
//
//public final class HttpHeaders {
//
//    var rawValue: OpaquePointer
//
//    var count: Int {
//        return aws_http_headers_count(self.rawValue)
//    }
//
//    public init(allocator: Allocator = defaultAllocator) throws {
//        guard let rawValue = aws_http_headers_new(allocator.rawValue) else {
//            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
//        }
//        self.rawValue = rawValue
//    }
//
//    convenience init(allocator: Allocator = defaultAllocator, fromArray: [HttpHeader]) throws {
//        try self.init(allocator: allocator)
//        try addArray(headers: fromArray)
//    }
//
//    /// Appends a `HttpHeader` into the instance using the provided `name` and `value`.
//    ///
//    /// - Parameters:
//    ///   - name:  The `HttpHeader` name.
//    ///   - value: The `HttpHeader value.
//    /// - Returns: `Bool`: True on success
//    public func add(name: String, value: String) throws {
//        guard (withByteCursorFromStrings(name, value) { nameCursor, valueCursor in
//            aws_http_headers_add(self.rawValue, nameCursor, valueCursor)
//        } == AWS_OP_SUCCESS) else {
//            throw CommonRunTimeError.crtError(.makeFromLastError())
//        }
//    }
//
//    /// Appends an array of `HttpHeaders` into the c instance of headers.
//    ///
//    /// - Parameters:
//    ///   - headers: The array of `HttpHeader` .
//    /// TODO: handle error
//    public func addArray(headers: [HttpHeader]) throws {
//        for header in headers {
//            try add(name: header.name, value: header.value)
//        }
//    }
//
//    /// Updates a header from the provided `name` with the new `value` in the c instance of headers.
//    /// - Returns: `Bool`: True on success
//    public func update(name: String, value: String) -> Bool {
//        return update(HttpHeader(name: name, value: value))
//    }
//
//    /// Updates or creates a new header from the provided `HttpHeader` into the c instance of headers.
//    ///
//    /// - Parameter header: The `HttpHeader` to update or append.
//    /// - Returns: `Bool`: True on success
//    public func update(_ header: HttpHeader) -> Bool {
//        // this function in c will update the header if it exists or create a new one if it's new.
//        return withByteCursorFromStrings(header.name, header.value) { nameCursor, valueCursor in
//            aws_http_headers_set(self.rawValue, nameCursor, valueCursor)
//        } == AWS_OP_SUCCESS
//    }
//
//    /// Gets a header by name from the `aws_http_headers` instance
//    ///
//    /// - Parameter name: The name of the header to get.
//    /// - Returns: `String?`: The value of the Header
//    public func get(name: String) -> String? {
//        var value = aws_byte_cursor()
//        if name.withByteCursor({ nameCursor in
//            aws_http_headers_get(self.rawValue, nameCursor, &value)
//        }) != AWS_OP_SUCCESS {
//            return nil
//        }
//        return value.toString()
//    }
//
//    /// Gets a header by name from the `aws_http_headers` instance
//    ///
//    /// - Parameter name: The name of the header to get.
//    /// - Returns: `String?`: The value of the Header
//    func get(index: Int) -> aws_http_header? {
//        var header = aws_http_header()
//        if aws_http_headers_get_index(self.rawValue, index, &header) == AWS_OP_SUCCESS {
//            return header
//        }
//        return nil
//    }
//
//    /// Gets all headers from the `aws_http_headers` instance
//    ///
//    /// - Returns:`[HttpHeader]`: The array of headers saved
//    public func getAll() -> [HttpHeader] {
//        var headers = [HttpHeader]()
//        for index in 0..<count {
//            var header = aws_http_header()
//            if aws_http_headers_get_index(self.rawValue, index, &header) == AWS_OP_SUCCESS {
//                headers.append(HttpHeader(rawValue: header))
//            } else {
//                fatalError("Invalid Index during get all headers")
//            }
//        }
//        return headers
//    }
//
//    /// Case-insensitively removes an `HttpHeader`, if it exists, from the instance.
//    ///
//    /// - Parameter name: The name of the `HttpHeader` to remove.
//    /// - Throws: CommonRuntimeError if header is not found
//    public func remove(name: String) throws {
//        guard (name.withByteCursor { nameCursor in
//            aws_http_headers_erase(self.rawValue, nameCursor)
//        } == AWS_OP_SUCCESS) else {
//            throw CommonRunTimeError.crtError(.makeFromLastError())
//        }
//    }
//
//    /// Removes all headers from the array
//    public func removeAll() {
//        aws_http_headers_clear(self.rawValue)
//    }
//
//    deinit {
//        aws_http_headers_release(self.rawValue)
//    }
//}
