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
//two things
//
//    struct aws_shutdown_callback_options shutdown_options = {
//.shutdown_callback_fn = s_event_loop_group_cleanup_completion_callback,
//.shutdown_callback_user_data = callback_data,
//};

//   self is this
//    let shutDownOptions = ShutDownCallbackOptions { semaphore in
//        semaphore.signal()
//    }
    func toShutDownCPointer() -> UnsafePointer<aws_shutdown_callback_options>? {

        //Creates a opaque pointer to self
        let shutDownPtr: UnsafeMutablePointer<ShutDownCallbackOptions>? = fromOptionalPointer(ptr: self)

        let options = aws_shutdown_callback_options(
                shutdown_callback_fn: { //this function is called to clean up elg with user data

                    (userData) in //1
                    guard let userdata = userData else {
                        return
                    }
                    //make sure user data is available, get that pointer in user data and deallocate
                    let pointer = userdata.assumingMemoryBound(to: ShutDownCallbackOptions.self)
                    pointer.pointee.shutDownCallback(pointer.pointee.semaphore) // calls signal
                    pointer.deinitializeAndDeallocate()

                }, shutdown_callback_user_data: shutDownPtr) //2, pointer to self.
        let ptr: UnsafePointer<aws_shutdown_callback_options>? = fromOptionalPointer(ptr: options)

        return ptr
        //create a pointer to options and pass that
    }
}
