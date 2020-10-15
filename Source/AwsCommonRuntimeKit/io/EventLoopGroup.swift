//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon
import AwsCIo

public final class EventLoopGroup {
    public var rawValue: UnsafeMutablePointer<aws_event_loop_group>

  public init(threadCount: UInt16 = 0, allocator: Allocator = defaultAllocator) throws {
    
    self.rawValue = aws_event_loop_group_new_default(allocator.rawValue, threadCount, nil)
  }

  deinit {
    aws_event_loop_group_release(rawValue)
  }
}
