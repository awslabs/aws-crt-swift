//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import Foundation

public struct ShutDownCallbackOptions {
    public typealias ShutDownCallback = (DispatchSemaphore) -> Void

    public let shutDownCallback: ShutDownCallback

    public let semaphore: DispatchSemaphore

    public init(shutDownCallback: @escaping ShutDownCallback) {
        self.shutDownCallback = shutDownCallback
        self.semaphore = DispatchSemaphore(value: 0)
    }
}

extension ShutDownCallbackOptions {
    func toShutDownCPointer() -> UnsafePointer<aws_shutdown_callback_options>? {
        let shutDownPtr: UnsafeMutablePointer<ShutDownCallbackOptions>? = fromOptionalPointer(ptr: self)
        let options = aws_shutdown_callback_options(shutdown_callback_fn: { (userData) in
            guard let userdata = userData else {
                return
            }
            let pointer = userdata.assumingMemoryBound(to: ShutDownCallbackOptions.self)
            pointer.pointee.shutDownCallback(pointer.pointee.semaphore)
            pointer.deinitializeAndDeallocate()
        }, shutdown_callback_user_data: shutDownPtr)
        let ptr: UnsafePointer<aws_shutdown_callback_options>? = fromOptionalPointer(ptr: options)

        return ptr
    }
}
