//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCHttp
import AwsCIo

public final class CRTHttpResponse: HttpMessage {
    init(message: OpaquePointer, allocator: Allocator) {
        super.init(owningMessage: aws_http_message_new_response(allocator.rawValue))
    }

    public var responseCode: Int? {
        get {
            var response: Int32 = 0
            if aws_http_message_get_response_status(self.rawValue, &response) != AWS_OP_SUCCESS {
                return nil
            }
            return Int(response)
        }
        set(value) {
            guard let value = value else { return }
            if aws_http_message_set_response_status(self.rawValue, Int32(value)) != AWS_OP_SUCCESS {
                self.responseCode = nil
            }
        }
    }
}
