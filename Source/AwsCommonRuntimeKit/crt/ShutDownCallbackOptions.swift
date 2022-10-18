//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCAuth
import Foundation

public class ShutDownCallbackOptions {
    public typealias ShutDownCallback = () -> Void
    let shutdownCallback: ShutDownCallback

    public init(shutDownCallback: @escaping ShutDownCallback) {
        self.shutdownCallback = shutDownCallback
    }

    func getCShutdownOptions() -> aws_shutdown_callback_options {
        var shutdown_options = aws_shutdown_callback_options()
        shutdown_options.shutdown_callback_fn = { rawValue in
            guard let rawValue = rawValue else {
                return
            }
            let shutDownCallbackOptions = Unmanaged<ShutDownCallbackOptions>.fromOpaque(rawValue).takeRetainedValue()
            shutDownCallbackOptions.shutdownCallback()
        }
        shutdown_options.shutdown_callback_user_data = Unmanaged<ShutDownCallbackOptions>.passRetained(self).toOpaque()
        return shutdown_options
    }

    func getCredentialProviderShutdownOptions() -> aws_credentials_provider_shutdown_options {
        var shutdown_options = aws_credentials_provider_shutdown_options()

        shutdown_options.shutdown_callback = { rawValue in
            guard let rawValue = rawValue else {
                return
            }
            let shutDownCallbackOptions = Unmanaged<ShutDownCallbackOptions>.fromOpaque(rawValue).takeRetainedValue()
            shutDownCallbackOptions.shutdownCallback()
        }
        shutdown_options.shutdown_user_data = Unmanaged<ShutDownCallbackOptions>.passRetained(self).toOpaque()
        return shutdown_options
    }
}
