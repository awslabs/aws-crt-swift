//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils

/// Request context used for resolving endpoint
public class EndpointsRequestContext {
    let rawValue: UnsafeMutablePointer<aws_endpoints_request_context>

    /// Initialize a new request context
    public init() throws {
        guard let rawValue = aws_endpoints_request_context_new(allocator.rawValue) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    /// Add a string endpoint parameter to the request context
    /// - Parameters:
    ///   - name: The name of the parameter
    ///   - value: The value of the parameter
    public func add(name: String, value: String?) throws {
        guard let value = value else {
            return
        }
        if withByteCursorFromStrings(name, value, { nameCursor, valueCursor in
            aws_endpoints_request_context_add_string(allocator.rawValue,
                                                     rawValue,
                                                     nameCursor,
                                                     valueCursor)
        }) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }

    /// Add a bool endpoint parameter to the request context
    /// - Parameters:
    ///   - name: The name of the parameter
    ///   - value: The value of the parameter
    public func add(name: String, value: Bool?) throws {
        guard let value = value else {
            return
        }
        if (name.withByteCursor { nameCursor in
            aws_endpoints_request_context_add_boolean(allocator.rawValue, rawValue, nameCursor, value)
        }) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }

    /// Add a string array endpoint parameter to the request context
    /// - Parameters:
    ///   - name: The name of the parameter
    ///   - value: The value of the parameter
    public func add(name: String, value: [String]?) throws {
        guard let value = value else {
            return
        }
        if (name.withByteCursor { nameCursor in
            withByteCursorArrayFromStringArray(value) { ptr, len in        
                aws_endpoints_request_context_add_string_array(allocator.rawValue, rawValue, nameCursor, ptr, len)
            }
        }) != AWS_OP_SUCCESS {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
    }

    deinit {
        aws_endpoints_request_context_release(rawValue)
    }
}
