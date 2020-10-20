//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public final class HttpHeaders {

    var rawValue: OpaquePointer

    var count: Int {
        return aws_http_headers_count(self.rawValue)
    }

    public init(allocator: Allocator = defaultAllocator) {
        self.rawValue = aws_http_headers_new(allocator.rawValue)
    }

    convenience init(allocator: Allocator = defaultAllocator, fromArray: [HttpHeader]) {
        self.init(allocator: allocator)
        addArray(headers: fromArray)
    }

    /// Appends a `HttpHeader` into the instance using the provided `name` and `value`.
    ///
    /// - Parameters:
    ///   - name:  The `HttpHeader` name.
    ///   - value: The `HttpHeader value.
    /// - Returns: `Bool`: True on success
    public func add(name: String, value: String) -> Bool {
        let nameByteCursor = name.awsByteCursor
        let valueByteCursor = value.awsByteCursor
        return aws_http_headers_add(self.rawValue, nameByteCursor, valueByteCursor) == AWS_OP_SUCCESS
    }

    /// Appends an array of `HttpHeaders` into the c instance of headers.
    ///
    /// - Parameters:
    ///   - headers: The array of `HttpHeader` .
    public func addArray(headers: [HttpHeader]) {
        for header in headers {
            _ = add(name: header.name, value: header.value)
        }
    }

    /// Updates a header from the provided `name` with the new `value` in the c instance of headers.
    ///
    /// - Parameter header: The `HttpHeader` to update or append.
    /// - Returns: `Bool`: True on success
    public func update(name: String, value: String) -> Bool {
        return update(HttpHeader(name: name, value: value))
    }

    /// Updates or creates a new header from the provided `HttpHeader` into the c instance of headers.
    ///
    /// - Parameter header: The `HttpHeader` to update or append.
    /// - Returns: `Bool`: True on success
    public func update(_ header: HttpHeader) -> Bool {
        //this function in c will update the header if it exists or create a new one if it's new.
        let name = header.name.awsByteCursor
        let value = header.value.awsByteCursor
        return aws_http_headers_set(self.rawValue,
                                    name,
                                    value) == AWS_OP_SUCCESS

    }

    /// Gets a header by name from the  `aws_http_headers` instance
    ///
    /// - Parameter name: The name of the header to get.
    /// - Returns: `String?`: The value of the Header
    public func get(name: String) -> String? {
        var value = aws_byte_cursor()
        let nameByteCursor = name.awsByteCursor
        if aws_http_headers_get(self.rawValue, nameByteCursor, &value) != AWS_OP_SUCCESS {
            return nil
        }
        return value.toString()
    }

    /// Gets all headers from the `aws_http_headers` instance
    ///
    /// - Returns:`[HttpHeader]`: The array of headers saved
    public func getAll() -> [HttpHeader] {
        var headers = [HttpHeader]()
        for index in 0...count {
            var header = HttpHeader(name: "", value: "")
            if aws_http_headers_get_index(self.rawValue, index, &header.rawValue) == AWS_OP_SUCCESS {
                headers.append(header)
            } else {
                continue
            }
        }
        return headers
    }

    /// Case-insensitively removes an `HttpHeader`, if it exists, from the instance.
    ///
    /// - Parameter name: The name of the `HttpHeader` to remove.
    /// - Returns: `Bool`: True on success
    public func remove(name: String) -> Bool {
        let nameByteCursor = name.awsByteCursor
        return aws_http_headers_erase(self.rawValue, nameByteCursor) == AWS_OP_SUCCESS
    }

    /// Removes all headers from the array
    public func removeAll() {
        aws_http_headers_clear(self.rawValue)
    }

    deinit {
        aws_http_headers_release(self.rawValue)
    }
}
