//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCCommon


extension Int32 {
    public func toString() -> String? {
        let u = UnicodeScalar(Int(self))
        // Convert UnicodeScalar to a String.
        if let u = u {
            return String(u)
        }
        return nil
    }
}

extension String {
    func toInt32() -> Int32 {
        return Int32(bitPattern: UnicodeScalar(self)?.value ?? 0)
    }
}
