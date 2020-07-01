//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp
import AwsCIo

public final class HttpRequest : HttpMessage {
    internal init(message: OpaquePointer) {
        super.init(borrowingMessage: message)
    }

    public init(allocator: Allocator = defaultAllocator) {
        super.init(owningMessage: aws_http_message_new_request(allocator.rawValue))
    }

    public var method: ByteCursor! {
        get {
            var result = aws_byte_cursor()
            if (aws_http_message_get_request_method(self.rawValue, &result) != AWS_OP_SUCCESS) {
                return nil
            }
            return result
        }
        set(value) {
            aws_http_message_set_request_method(self.rawValue, value.rawValue)
        }
    }

    public var path: ByteCursor! {
        get {
            var result = aws_byte_cursor()
            if (aws_http_message_get_request_path(self.rawValue, &result) != AWS_OP_SUCCESS) {
                return nil
            }
            return result
        }
        set(value) {
            // TODO: What when this fails?
            aws_http_message_set_request_path(self.rawValue, value.rawValue)
        }
    }
}

