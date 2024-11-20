//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import AwsCCommon
@testable import AwsCommonRuntimeKit

class CBORTests: XCBaseTestCase {

    func testCBOREncode() async throws {
        let uintValue: CBORType = .uint64(100)

        // encode the values
        let encoder = CBOREncoder()
        encoder.encode(uintValue)
        let encoded = encoder.getEncoded();

        print(encoded)

        let decoder = CBORDecoder(data: encoded)
        while decoder.hasNext() {
           let value = try! decoder.decodeNext() 
           XCTAssertEqual(value, .uint64(100))
           
        }

    }

}
