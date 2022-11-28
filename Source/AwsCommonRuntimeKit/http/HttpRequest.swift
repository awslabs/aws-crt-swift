//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import AwsCIo
import AwsCCommon
// TODO: HttpRequest & HttpMessage relationship
public class HttpRequest: HttpMessage {

    public override init(allocator: Allocator = defaultAllocator) throws {
        try super.init(allocator: allocator)
    }

    public override init(headers: HttpHeaders, allocator: Allocator = defaultAllocator) throws {
        try super.init(headers: headers, allocator: allocator)
    }

    public var method: String? {
        get {
            var result = aws_byte_cursor()
            if aws_http_message_get_request_method(self.rawValue, &result) != AWS_OP_SUCCESS {
                return nil
            }
            return result.toOptionalString()
        }
        set(value) {
            guard let value = value else { return }
            if (value.withByteCursor { valueCursor in
                aws_http_message_set_request_method(self.rawValue, valueCursor)
            }) != AWS_OP_SUCCESS {
                self.method = nil
            }
        }
    }

    public var path: String? {
        get {
            var result = aws_byte_cursor()
            if aws_http_message_get_request_path(self.rawValue, &result) != AWS_OP_SUCCESS {
                return nil
            }
            return result.toOptionalString()
        }
        set(value) {
            if withByteCursorFromStrings(value, { valueCursor in
                return aws_http_message_set_request_path(self.rawValue, valueCursor)
            }) != AWS_OP_SUCCESS {
                self.path = nil
            }
        }
    }
}
