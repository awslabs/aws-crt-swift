//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon
import AwsCIo

public final class EventLoopGroup {
  public var rawValue = aws_event_loop_group()

  public init(threadCount: UInt16 = 0, allocator: Allocator = defaultAllocator) throws {
    zeroStruct(&self.rawValue)
    if (aws_event_loop_group_default_init(&self.rawValue, allocator.rawValue, threadCount) != AWS_OP_SUCCESS) {
      throw AwsCommonRuntimeError()
    }
  }

  deinit {
    aws_event_loop_group_clean_up(&rawValue)
    zeroStruct(&rawValue)
  }
}
