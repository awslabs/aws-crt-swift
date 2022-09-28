//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

public struct ClientBootstrapCallbackData {
    public typealias OnShutDownComplete = (DispatchSemaphore) -> Void
    let onShutDownComplete: OnShutDownComplete
    let shutDownSemaphore: DispatchSemaphore

    public init(onShutDownComplete: @escaping OnShutDownComplete) {
        self.onShutDownComplete = onShutDownComplete
        shutDownSemaphore = DispatchSemaphore(value: 0)
    }
}
