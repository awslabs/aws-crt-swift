//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit
import AwsCCommon

class UtilitiesTests: XCBaseTestCase {

    func testStringArrayToByteCursorArray() {
        let strings1 = ["a", "b"]
        strings1.withByteCursorArray { cursors, len in
            XCTAssertEqual(len, 2)
            for i in 0..<len {
                withUnsafePointer(to: cursors[i]) { pointer in
                    XCTAssertTrue(aws_byte_cursor_is_valid(pointer))
                }
            }
        }

        let strings2: [String] = []
        strings2.withByteCursorArray { cursors, len in
            XCTAssertEqual(len, 0)
        }
    }
}

