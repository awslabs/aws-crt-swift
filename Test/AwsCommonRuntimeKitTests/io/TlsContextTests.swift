//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AwsCommonRuntimeKit
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest

class TlsContextTests: CrtXCBaseTestCase {
    func testCreateTlsContextWithOptions() throws {
        let options = TlsContextOptions(defaultClientWithAllocator: allocator)
        let context = try TlsContext(options: options, mode: .client, allocator: allocator)
        _ = context.newConnectionOptions()
    }
}
