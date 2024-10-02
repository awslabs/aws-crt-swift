//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public class TLSSecitemOptions : CStruct {
    var rawValue: UnsafeMutablePointer<aws_secitem_options>

    public init(
        certLabel: String? = nil,
        keyLabel: String? = nil) {
        
            self.rawValue = allocator.allocate(capacity: 1)
            
            self.rawValue.pointee.cert_label = certLabel?.withByteCursorPointer { certLabelCursorPointer in
                aws_string_new_from_cursor(
                    allocator.rawValue,
                    certLabelCursorPointer)
            }
            
            self.rawValue.pointee.key_label = keyLabel?.withByteCursorPointer { keyLabelCursorPointer in
                aws_string_new_from_cursor(
                    allocator.rawValue,
                    keyLabelCursorPointer)
            }
    }

    typealias RawType = aws_secitem_options
    func withCStruct<Result>(_ body: (aws_secitem_options) -> Result) -> Result {
        return body(rawValue.pointee)
    }
    
    deinit {
        aws_tls_secitem_options_clean_up(rawValue)
        allocator.release(rawValue)
    }
}
