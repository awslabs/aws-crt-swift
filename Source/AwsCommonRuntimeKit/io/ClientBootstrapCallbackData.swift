//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

struct ClientBootstrapCallbackData {
    typealias OnShutDownComplete = () -> Void
    let onShutDownComplete: OnShutDownComplete?
    let shutDownSemaphore: DispatchSemaphore

    init(onShutDownComplete: OnShutDownComplete? = nil,
         shutDownSemaphore: DispatchSemaphore) {
        self.onShutDownComplete = onShutDownComplete
        self.shutDownSemaphore = shutDownSemaphore
    }
}
