//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon

final class AWSString {
    let rawValue: UnsafeMutablePointer<aws_string>

    init(_ str: String, allocator: Allocator) {
        self.rawValue = aws_string_new_from_array(allocator.rawValue, str, str.count)
    }

    var count: Int {
        return self.rawValue.pointee.len
    }

    deinit {
        aws_string_destroy(self.rawValue)
    }
}

extension String {
    init?(awsString: UnsafePointer<aws_string>, encoding: String.Encoding = .utf8) {
        self.init(cString: aws_string_c_str(awsString), encoding: encoding)
    }

}
