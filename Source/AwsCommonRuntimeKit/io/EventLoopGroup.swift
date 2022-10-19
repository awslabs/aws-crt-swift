//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon
import AwsCIo
import Foundation

public final class EventLoopGroup {
    let rawValue: UnsafeMutablePointer<aws_event_loop_group>
    public init(threadCount: UInt16 = 0,
                allocator: Allocator = defaultAllocator,
                shutdownCallback: ShutdownCallback? = nil) throws {
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        guard let rawValue: UnsafeMutablePointer<aws_event_loop_group> = withOptionalUnsafePointer(
                shutdownCallbackCore?.getRetainedShutdownOptions(), { shutdownOptionsPointer in
            aws_event_loop_group_new_default(allocator.rawValue, threadCount, shutdownOptionsPointer)
        }) else {
            shutdownCallbackCore?.release()
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    deinit {
        aws_event_loop_group_release(rawValue)
    }
}
