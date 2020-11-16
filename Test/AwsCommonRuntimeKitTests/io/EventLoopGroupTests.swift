//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class EventLoopGroupTests: CrtXCBaseTestCase {

    func testCanCreateGroup() {
        let shutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }
        _ = EventLoopGroup(allocator: allocator, shutDownOptions: shutDownOptions)
    }

    func testCanCreateGroupWithThreads() {
        let shutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }
        _ = EventLoopGroup(threadCount: 2, allocator: allocator, shutDownOptions: shutDownOptions)
    }
}
