//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class TlsContextTests: CrtXCBaseTestCase {

  func testCreateTlsContextWithOptions() throws {
    let options = TlsContextOptions(defaultClientWithAllocator: allocator)
    let context = try TlsContext(options: options, mode: .client, allocator: allocator)
    _ = TlsConnectionOptions(context: context, allocator: allocator)
  }
}
