//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import Foundation

public class ShutDownCallbackOptions {
    public typealias ShutDownCallback = (_ userData: Any?) -> Void
    let rawValue: UnsafeMutablePointer<aws_shutdown_callback_options>
    public let shutDownCallback: ShutDownCallback
    let userData: Any?
    let allocator: Allocator
    public init(shutDownCallback: @escaping ShutDownCallback, userData: Any? = nil, allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
        self.shutDownCallback = shutDownCallback
        self.userData = userData
        rawValue = allocator.allocate(capacity: 1)
        rawValue.pointee.shutdown_callback_fn = { rawValue in
            guard let rawValue = rawValue else {
                return
            }
            let shutdownCallbackOptions = Unmanaged<ShutDownCallbackOptions>.fromOpaque(rawValue).takeRetainedValue()
            shutdownCallbackOptions.shutDownCallback(shutdownCallbackOptions.userData)
        }
        rawValue.pointee.shutdown_callback_user_data = Unmanaged<ShutDownCallbackOptions>.passRetained(self).toOpaque()
    }

    deinit {
        allocator.release(rawValue)
    }

}

