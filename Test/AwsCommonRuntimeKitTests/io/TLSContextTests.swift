//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class TLSContextTests: XCBaseTestCase {

  func testCreateTlsContextWithOptions() throws {
    let options = TLSContextOptions(allocator: allocator)
    let context = try TLSContext(options: options, mode: .client, allocator: allocator)
    _ = TLSConnectionOptions(context: context, allocator: allocator)
  }
}
