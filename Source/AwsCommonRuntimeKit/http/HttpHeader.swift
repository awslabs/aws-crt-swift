//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp

public struct HttpHeaders {
  
    public var headers: [HttpHeader] = []

    public init() { }
    //TODO: if aws_http_headers is exposed we can map it appropriately
    init(headers: [aws_http_header]) {
        for header in headers {
            add(name: header.name.toString(), value: header.value.toString())
        }
    }

    /// Case-insensitively updates or appends an `HttpHeader` into the instance using the provided `name` and `value`.
    ///
    /// - Parameters:
    ///   - name:  The `HttpHeader` name.
    ///   - value: The `HttpHeader value.
    public mutating func add(name: String, value: String) {
        update(HttpHeader(name: name, value: value))
    }

    /// Case-insensitively updates or appends the provided `HttpHeader` into the instance.
    ///
    /// - Parameter header: The `HttpHeader` to update or append.
    public mutating func update(_ header: HttpHeader) {
        guard let index = headers.index(of: header.name.toString()) else {
            headers.append(header)
            return
        }

        headers.replaceSubrange(index...index, with: [header])
    }

    /// Case-insensitively removes an `HttpHeader`, if it exists, from the instance.
    ///
    /// - Parameter name: The name of the `HttpHeader` to remove.
    public mutating func remove(name: String) {
        guard let index = headers.index(of: name) else { return }

        headers.remove(at: index)
    }

}

extension Array where Element == HttpHeader {
    /// Case-insensitively finds the index of an `HttpHeader` with the provided name, if it exists.
    func index(of name: String) -> Int? {
        let lowercasedName = name.lowercased()
        return firstIndex { $0.name.toString().lowercased() == lowercasedName }
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
