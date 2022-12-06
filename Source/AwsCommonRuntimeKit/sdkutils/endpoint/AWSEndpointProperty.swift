//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

/// Struct that represents endpoint property which can be a boolean, string or array of endpoint properties
enum AWSEndpointProperty {
    case bool(Bool)
    case string(String)
    indirect case array([AWSEndpointProperty])
    indirect case dictionary([String: AWSEndpointProperty])

    func toAnyHashable() -> AnyHashable {
        switch self {
        case .bool(let value):
            return AnyHashable(value)
        case .string(let value):
            return AnyHashable(value)
        case .array(let value):
            return AnyHashable(value.map { $0.toAnyHashable() })
        case .dictionary(let value):
            return AnyHashable(value.mapValues { $0.toAnyHashable() })
        }
    }
}

/// Decodable conformance
extension AWSEndpointProperty: Decodable {
    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: AWSEndpointPropertyCodingKeys.self) {
            self = AWSEndpointProperty(from: container)
        } else if let container = try? decoder.unkeyedContainer() {
            self = AWSEndpointProperty(from: container)
        } else if let container = try? decoder.singleValueContainer() {
            self = AWSEndpointProperty(from: container)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: ""))
        }
    }

    init(from container: KeyedDecodingContainer<AWSEndpointPropertyCodingKeys>) {
        var dict: [String: AWSEndpointProperty] = [:]
        for key in container.allKeys {
            if let value = try? container.decode(Bool.self, forKey: key) {
                dict[key.stringValue] = .bool(value)
            } else if let value = try? container.decode(String.self, forKey: key) {
                dict[key.stringValue] = .string(value)
            } else if let value = try? container.nestedContainer(
                keyedBy: AWSEndpointPropertyCodingKeys.self,
                forKey: key
            ) {
                dict[key.stringValue] = AWSEndpointProperty(from: value)
            } else if let value = try? container.nestedUnkeyedContainer(forKey: key) {
                dict[key.stringValue] = AWSEndpointProperty(from: value)
            }
        }
        self = .dictionary(dict)
    }

    init(from container: UnkeyedDecodingContainer) {
        var container = container
        var arr: [AWSEndpointProperty] = []
        while !container.isAtEnd {
            if let value = try? container.decode(Bool.self) {
                arr.append(.bool(value))
            } else if let value = try? container.decode(String.self) {
                arr.append(.string(value))
            } else if let value = try? container.nestedContainer(keyedBy: AWSEndpointPropertyCodingKeys.self) {
                arr.append(AWSEndpointProperty(from: value))
            } else if let value = try? container.nestedUnkeyedContainer() {
                arr.append(AWSEndpointProperty(from: value))
            }
        }
        self = .array(arr)
    }

    init(from container: SingleValueDecodingContainer) {
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            assertionFailure("Invalid EndpointProperty")
            self = .string("")
        }
    }
}

extension Dictionary where Key == String, Value == AWSEndpointProperty {
    /// Converts EndpointProperty to a dictionary of `String`: `AnyHashable`
    /// - Returns: Dictionary of `String`: `AnyHashable`
    func toStringHashableDictionary() -> [String: AnyHashable] {
        var dict: [String: AnyHashable] = [:]
        for (key, value) in self {
            dict[key] = value.toAnyHashable()
        }
        return dict
    }
}

/// Coding keys for `EndpointProperty`
struct AWSEndpointPropertyCodingKeys: CodingKey {
    var stringValue: String

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?

    init(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}
