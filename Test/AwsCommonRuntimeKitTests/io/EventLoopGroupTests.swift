//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class EventLoopGroupTests: CrtXCBaseTestCase {

  func testCanCreateGroup() throws {
    let _ = try EventLoopGroup(allocator: allocator)
  }

  func testCanCreateGroupWithThreads() throws {
    let _ = try EventLoopGroup(threadCount: 2, allocator: allocator)
  }
}


