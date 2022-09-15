//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo

public final class EventLoopGroup {
    public var rawValue: UnsafeMutablePointer<aws_event_loop_group>

    public let shutDownOptions: ShutDownCallbackOptions?
    //Todo: confirm this
    public init(threadCount: UInt16 = 0,
                allocator: Allocator = defaultAllocator,
                shutDownOptions: ShutDownCallbackOptions? = nil) {
        let ptr = shutDownOptions?.toShutDownCPointer()
        self.shutDownOptions = shutDownOptions

        rawValue = aws_event_loop_group_new_default(allocator.rawValue, threadCount, ptr)
    }

    deinit {
        aws_event_loop_group_release(rawValue)
        if let shutDownOptions = shutDownOptions {
            shutDownOptions.semaphore.wait()
        }
    }
}
