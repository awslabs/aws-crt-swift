//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon
import AwsCIo
import Foundation

public final class EventLoopGroup {
    public var rawValue: UnsafeMutablePointer<aws_event_loop_group>
    
    public let shutDownOptions: ShutDownCallbackOptions?
    
    public init(threadCount: UInt16 = 0, allocator: Allocator = defaultAllocator, shutDownOptions: ShutDownCallbackOptions? = nil) throws {
        var ptr: UnsafePointer<aws_shutdown_callback_options>?
        if let shutDownOptions = shutDownOptions {
            let shutDownPtr = UnsafeMutablePointer<ShutDownCallbackOptions>.allocate(capacity: 1)
            shutDownPtr.initialize(to: shutDownOptions)
            var options = aws_shutdown_callback_options(shutdown_callback_fn: { (userData) in
                guard let userdata = userData else {
                    return
                }
                let pointer = userdata.assumingMemoryBound(to: ShutDownCallbackOptions.self)
                defer { pointer.deinitializeAndDeallocate() }
                pointer.pointee.shutDownCallback(pointer.pointee.semaphore)
                
            }, shutdown_callback_user_data: shutDownPtr)
            
            ptr = UnsafePointer(&options)
        }
        self.shutDownOptions = shutDownOptions
        self.rawValue = aws_event_loop_group_new_default(allocator.rawValue, threadCount, ptr)
    }
    
    deinit {
        aws_event_loop_group_release(rawValue)
        if let shutDownOptions = shutDownOptions {
            shutDownOptions.semaphore.wait()
        }
    }
}
