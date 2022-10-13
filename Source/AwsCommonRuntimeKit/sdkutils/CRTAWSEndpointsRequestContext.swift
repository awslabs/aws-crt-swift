//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils

/// Request context used for resolving endpoint
public class CRTAWSEndpointsRequestContext {
    let rawValue: OpaquePointer

    /// Initialize a new request context
    /// - Parameter allocator: Allocator to use for request context creation
    public init(allocator: Allocator = defaultAllocator) throws {
        guard let rawValue = aws_endpoints_request_context_new(allocator.rawValue) else {
            throw CRTError.crtError(AWSError.makeFromLastError())
        }

        self.rawValue = rawValue
    }

    /// Add a string endpoint parameter to the request context
    /// - Parameters:
    ///   - name: The name of the parameter
    ///   - value: The value of the parameter
    ///   - allocator: The allocator to use for the parameter
    public func add(name: String, value: String?, allocator: Allocator = defaultAllocator) throws {
        guard let value = value else {
            return
        }
        let namePtr: UnsafeMutablePointer<aws_byte_cursor> = fromPointer(ptr: name.awsByteCursor)
        let valuePtr: UnsafeMutablePointer<aws_byte_cursor> = fromPointer(ptr: value.awsByteCursor)
        let success = aws_endpoints_request_context_add_string(allocator.rawValue,
                                                               rawValue,
                                                               namePtr.pointee,
                                                               valuePtr.pointee)
        if success != 0 {
            throw CRTError.crtError(AWSError.makeFromLastError())
        }
    }

    /// Add a bool endpoint parameter to the request context
    /// - Parameters:
    ///   - name: The name of the parameter
    ///   - value: The value of the parameter
    ///   - allocator: The allocator to use for the parameter
    public func add(name: String, value: Bool?, allocator: Allocator = defaultAllocator) throws {
        guard let value = value else {
            return
        }
        let namePtr: UnsafeMutablePointer<aws_byte_cursor> = fromPointer(ptr: name.awsByteCursor)
        let success = aws_endpoints_request_context_add_boolean(allocator.rawValue, rawValue, namePtr.pointee, value)
        if success != 0 {
            throw CRTError.crtError(AWSError.makeFromLastError())
        }
    }
    
    deinit {
        aws_endpoints_request_context_release(rawValue)
    }
}
