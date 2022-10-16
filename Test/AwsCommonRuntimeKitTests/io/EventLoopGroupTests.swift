//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class EventLoopGroupTests: CrtXCBaseTestCase {

    func testCanCreateGroup() throws {
        //TODO
//        let shutDownOptions = ShutDownCallbackOptions { semaphore in
//            semaphore.signal()
//        }
        _ = try EventLoopGroup(allocator: allocator, shutDownOptions: nil)
    }

    func testCanCreateGroupWithThreads() throws {
//        let shutDownOptions = ShutDownCallbackOptions { semaphore in
//            semaphore.signal()
//        }
        _ = try EventLoopGroup(threadCount: 2, allocator: allocator, shutDownOptions: nil)
    }
}
