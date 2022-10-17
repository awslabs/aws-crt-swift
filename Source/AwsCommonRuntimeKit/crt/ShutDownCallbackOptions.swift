//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import Foundation

public class ShutDownCallbackOptions {
    public typealias ShutDownCallback = () -> Void
    let rawValue: UnsafeMutablePointer<aws_shutdown_callback_options>
    let shutdownCallback: ShutDownCallback
    let allocator: Allocator

    public init(allocator: Allocator = defaultAllocator, shutDownCallback: @escaping ShutDownCallback) {
        self.allocator = allocator
        rawValue = allocator.allocate(capacity: 1)
        self.shutdownCallback = shutDownCallback
        rawValue.pointee.shutdown_callback_fn = { rawValue in
            guard let rawValue = rawValue else {
                return
            }
            let shutDownCallbackOptions = Unmanaged<ShutDownCallbackOptions>.fromOpaque(rawValue).takeRetainedValue()
            shutDownCallbackOptions.shutdownCallback()
        }
        rawValue.pointee.shutdown_callback_user_data = Unmanaged<ShutDownCallbackOptions>.passRetained(self).toOpaque()
    }

    deinit {
        allocator.release(rawValue)
    }

}

