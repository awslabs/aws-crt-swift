//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class HttpHeaderTests: CrtXCBaseTestCase {
    func testCreateHttpHeaders() throws {
        _ = HttpHeaders(allocator: self.allocator)
    }
}
