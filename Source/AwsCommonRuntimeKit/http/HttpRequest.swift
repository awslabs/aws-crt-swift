//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import AwsCIo

public final class HttpRequest: HttpMessage {
    init(message: OpaquePointer) {
        super.init(borrowingMessage: message)
    }

    public init(allocator: Allocator = defaultAllocator) {
        super.init(owningMessage: aws_http_message_new_request(allocator.rawValue))
    }

    public init(allocator: Allocator = defaultAllocator, headers: HttpHeaders) {
        super.init(owningMessage: aws_http_message_new_request_with_headers(allocator.rawValue, headers.rawValue))
    }

    public var method: String? {
        get {
            var result = aws_byte_cursor()
            if aws_http_message_get_request_method(rawValue, &result) != AWS_OP_SUCCESS {
                return nil
            }
            return result.toString()
        }
        set(value) {
            guard let value = value else { return }
            if aws_http_message_set_request_method(rawValue, value.awsByteCursor) != AWS_OP_SUCCESS {
                self.method = nil
            }
        }
    }

    public var path: String? {
        get {
            var result = aws_byte_cursor()
            if aws_http_message_get_request_path(rawValue, &result) != AWS_OP_SUCCESS {
                return nil
            }
            return result.toString()
        }
        set(value) {
            if aws_http_message_set_request_path(rawValue,
                                                 value?.awsByteCursor ?? "".awsByteCursor) != AWS_OP_SUCCESS {
                self.path = nil
            }
        }
    }
}
