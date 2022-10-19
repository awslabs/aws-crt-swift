//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCAuth

public typealias ShutdownCallback = () -> Void
public class ShutdownCallbackOptions {
    let shutdownCallback: ShutdownCallback
    init?(_ shutdownCallback: ShutdownCallback?) {
        guard let shutdownCallback = shutdownCallback else {
            return nil
        }
        self.shutdownCallback = shutdownCallback
    }

    func getCShutdownOptions() -> aws_shutdown_callback_options {
        var shutdown_options = aws_shutdown_callback_options()
        shutdown_options.shutdown_callback_fn = { rawValue in
            guard let rawValue = rawValue else {
                return
            }
            let shutdownCallbackOptions = Unmanaged<ShutdownCallbackOptions>.fromOpaque(rawValue).takeRetainedValue()
            shutdownCallbackOptions.shutdownCallback()
        }
        shutdown_options.shutdown_callback_user_data = Unmanaged<ShutdownCallbackOptions>.passRetained(self).toOpaque()
        return shutdown_options
    }

    func release() {
        Unmanaged<ShutdownCallbackOptions>.passUnretained(self).release()
    }

    func getCredentialProviderShutdownOptions() -> aws_credentials_provider_shutdown_options {
        var shutdown_options = aws_credentials_provider_shutdown_options()

        shutdown_options.shutdown_callback = { rawValue in
            guard let rawValue = rawValue else {
                return
            }
            let shutdownCallbackOptions = Unmanaged<ShutdownCallbackOptions>.fromOpaque(rawValue).takeRetainedValue()
            shutdownCallbackOptions.shutdownCallback()
        }
        shutdown_options.shutdown_user_data = Unmanaged<ShutdownCallbackOptions>.passRetained(self).toOpaque()
        return shutdown_options
    }

    func getIMDSClientShutdownOptions() -> aws_imds_client_shutdown_options {
        var shutdown_options = aws_imds_client_shutdown_options()

        shutdown_options.shutdown_callback = { rawValue in
            guard let rawValue = rawValue else {
                return
            }
            let shutdownCallbackOptions = Unmanaged<ShutdownCallbackOptions>.fromOpaque(rawValue).takeRetainedValue()
            shutdownCallbackOptions.shutdownCallback()
        }
        shutdown_options.shutdown_user_data = Unmanaged<ShutdownCallbackOptions>.passRetained(self).toOpaque()
        return shutdown_options
    }

    deinit {
        print("release shutdown callback")
    }
}
