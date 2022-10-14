//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils
import Foundation

/// Resolved endpoint
public class CRTAWSEndpointResolvedEndpoint {
    let rawValue: OpaquePointer

    /// Initialize a new resolved endpoint
    /// - Parameter rawValue: The raw value of the resolved endpoint
    internal init(rawValue: OpaquePointer) {
        self.rawValue = rawValue

        aws_endpoints_resolved_endpoint_acquire(rawValue)
    }

    /// Get the type of the resolved endpoint
    /// - Returns: The type of the resolved endpoint
    public func getType() -> CRTAWSEndpointsResolvedEndpointType {
        let type = aws_endpoints_resolved_endpoint_get_type(rawValue)
        return CRTAWSEndpointsResolvedEndpointType(rawValue: type)
    }

    /// Get the URL of the resolved endpoint
    /// - Returns: The URL of the resolved endpoint
    public func getURL() throws -> String? {
        let urlOut = UnsafeMutablePointer<aws_byte_cursor>.allocate(capacity: 1)
        defer {
            urlOut.deallocate()
        }
        let success = aws_endpoints_resolved_endpoint_get_url(rawValue, urlOut)
        if success != 0 {
            throw CRTError.crtError(AWSError.makeFromLastError())
        }
        return urlOut.pointee.toString()
    }

    /// Get the properties of the resolved endpoint
    /// - Returns: The properties of the resolved endpoint
    public func getProperties() throws -> [String: AnyHashable]? {
        let propsOut = UnsafeMutablePointer<aws_byte_cursor>.allocate(capacity: 1)
        defer {
            propsOut.deallocate()
        }
        let success = aws_endpoints_resolved_endpoint_get_properties(rawValue, propsOut)
        if success != 0 {
            throw CRTError.crtError(AWSError.makeFromLastError())
        }
        guard let data = propsOut.pointee.toString()?.data(using: .utf8) else {
            return nil
        }
        return try JSONDecoder().decode([String: EndpointProperty].self, from: data).toStringHashableDictionary()
    }

    /// Get the error of the resolved endpoint
    /// - Parameter allocator: The allocator to use for the error
    public func getError() throws -> String? {
        let errorOut = UnsafeMutablePointer<aws_byte_cursor>.allocate(capacity: 1)
        defer {
            errorOut.deallocate()
        }
        let success = aws_endpoints_resolved_endpoint_get_error(rawValue, errorOut)
        if success != 0 {
            throw CRTError.crtError(AWSError.makeFromLastError())
        }
        return errorOut.pointee.toString()
    }

    /// Get headers of the resolved endpoint
    /// - Returns: The headers of the resolved endpoint
    public func getHeaders() throws -> [String: [String]]? {
        let headersOut: UnsafeMutablePointer<UnsafePointer<aws_hash_table>?>
            = UnsafeMutablePointer<UnsafePointer<aws_hash_table>?>.allocate(capacity: 1)
        defer {
            headersOut.deallocate()
        }
        let success = aws_endpoints_resolved_endpoint_get_headers(rawValue, headersOut)
        if success != 0 {
            throw CRTError.crtError(AWSError.makeFromLastError())
        }

        var headers: [String: [String]] = [:]
        var iter = aws_hash_iter_begin(headersOut.pointee)

        while !aws_hash_iter_done(&iter) {
            // Get the key
            let keyPtr = iter.element.key.bindMemory(to: aws_string.self, capacity: 1)
            guard let key = String(awsString: keyPtr) else {
                throw CRTError.stringConversionError(keyPtr)
            }

            // Get the value
            let arrayPtr = iter.element.value.bindMemory(to: aws_array_list.self, capacity: 1)
            var array: [String] = []
            for index in 0..<aws_array_list_length(arrayPtr) {
                var valPtr: UnsafeMutableRawPointer! = nil
                defer {
                    valPtr?.deallocate()
                }
                aws_array_list_get_at(arrayPtr, &valPtr, index)
                let strPtr = valPtr.bindMemory(to: aws_string.self, capacity: 1)
                guard let val = String(awsString: strPtr) else {
                    throw CRTError.stringConversionError(strPtr)
                }
                array.append(val)
            }

            headers[key] = array
            aws_hash_iter_next(&iter)
        }

        return headers
    }

    deinit {
        aws_endpoints_resolved_endpoint_release(rawValue)
    }
}
