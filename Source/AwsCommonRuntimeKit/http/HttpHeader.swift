//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp

public struct HttpHeaders {
    public var headers: [Header] = []

    public init() { }

    /// Creates an instance from a `[String: String]`. Duplicate case-insensitive names are collapsed into the last name
    /// and value encountered.
    public init(_ dictionary: [String: String]) {
        self.init()

        dictionary.forEach { update(Header(name: $0.key, value: $0.value)) }
    }

    /// Case-insensitively updates or appends an `HTTPHeader` into the instance using the provided `name` and `value`.
    ///
    /// - Parameters:
    ///   - name:  The `HTTPHeader` name.
    ///   - value: The `HTTPHeader value.
    public mutating func add(name: String, value: String) {
        update(Header(name: name, value: value))
    }

    /// Case-insensitively updates or appends the provided `HTTPHeader` into the instance.
    ///
    /// - Parameter header: The `HTTPHeader` to update or append.
    public mutating func update(_ header: Header) {
        guard let index = headers.index(of: header.name) else {
            headers.append(header)
            return
        }

        headers.replaceSubrange(index...index, with: [header])
    }

    /// Case-insensitively removes an `HTTPHeader`, if it exists, from the instance.
    ///
    /// - Parameter name: The name of the `HTTPHeader` to remove.
    public mutating func remove(name: String) {
        guard let index = headers.index(of: name) else { return }

        headers.remove(at: index)
    }
}


public struct Header {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

extension Header {
    func toAWSHttpHeader() -> aws_http_header {

    }
}