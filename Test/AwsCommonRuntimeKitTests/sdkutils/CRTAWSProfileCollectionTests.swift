//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class CRTAWSProfileCollectionTests: CrtXCBaseTestCase {
    func testGetProfileCollectionFromBuffer() {
        let fakeConfig = "[default]\r\nregion=us-west-2".data(using: .utf8)!
        let buffer = ByteBuffer(data: fakeConfig)
        let profileCollection = CRTAWSProfileCollection(fromBuffer: buffer, source: .config)
        XCTAssertNotNil(profileCollection)
    }
    
    func testGet
}
