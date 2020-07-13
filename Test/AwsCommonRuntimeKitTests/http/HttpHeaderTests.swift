//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class HttpHeaderTests : CrtXCBaseTestCase {
    func testCreateHttpHeaders() throws {
        let _ = HttpHeaders(allocator: self.allocator)
    }
    
    func testAnotherCreateHttpHeaders() throws {
        let _ = HttpHeaders(allocator: self.allocator)
    }
}
