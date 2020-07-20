//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp

public final class HttpHeaders {
    
    let rawValue: OpaquePointer
    
    var count: Int {
        get {
            aws_http_headers_count(self.rawValue)
        }
    }

    public init(allocator: Allocator = defaultAllocator) {
        self.rawValue = aws_http_headers_new(allocator.rawValue)
    }

    /// Updates or appends an `HttpHeader` into the instance using the provided `name` and `value`.
    ///
    /// - Parameters:
    ///   - name:  The `HttpHeader` name.
    ///   - value: The `HttpHeader value.
    /// - Returns: `Bool`: True on success
    public func add(name: String, value: String) -> Bool {
        return update(HttpHeader(name: name, value: value))
    }

    /// Updates or appends the provided `HttpHeader` into the instance.
    ///
    /// - Parameter header: The `HttpHeader` to update or append.
    /// - Returns: `Bool`: True on success
    public func update(_ header: HttpHeader) -> Bool {
        //this function in c will update the header if it exists or create a new one if it's new.
        return aws_http_headers_set(self.rawValue, header.name, header.value) == AWS_OP_SUCCESS
        
    }
    
    /// Gets a header by name from the  `aws_http_headers` instance
    ///
    /// - Parameter name: The name of the header to get.
    /// - Returns: `String?`: The value of the Header
    public func get(name: String) -> String? {
        var value = aws_byte_cursor()
        if aws_http_headers_get(self.rawValue, name.awsByteCursor, &value) != AWS_OP_SUCCESS {
            return nil
        }
        return value.toString()
    }
    
    /// Gets all headers from the `aws_http_headers` instance
    ///
    /// - Returns:`[HttpHeader]`: The array of headers saved
    public func getAll() -> [HttpHeader] {
        var headers = [HttpHeader]()
        for i in 0...count {
            var header = HttpHeader()
            if aws_http_headers_get_index(self.rawValue, i, &header) == AWS_OP_SUCCESS {
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
        return aws_http_headers_erase(self.rawValue, name.awsByteCursor) == AWS_OP_SUCCESS
    }
    
    /// Removes all headers from the array
    public func removeAll() {
        aws_http_headers_clear(self.rawValue)
    }
    
    deinit {
        aws_http_headers_release(self.rawValue)
    }

}

public typealias HttpHeader = aws_http_header

public extension HttpHeader {
    init(name: String, value: String, compression: HttpHeaderCompression = .useCache) {
        self.init()
        self.name = name.awsByteCursor
        self.value = value.awsByteCursor
        self.compression = compression.rawValue
    }
}
