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
