//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCAuth

public typealias ShutdownCallback = () -> Void

class ShutdownCallbackCore {
    let shutdownCallback: ShutdownCallback
    init?(_ shutdownCallback: ShutdownCallback?) {
        guard let shutdownCallback = shutdownCallback else {
            return nil
        }
        self.shutdownCallback = shutdownCallback
    }

    /// Calling this function performs a manual retain on the ShutdownCallbackCore.
    /// and returns aws_shutdown_callback_options. When the shutdown finally fires,
    /// it will manually release ShutdownCallbackCore.
    ///
    /// If you fail to create something that uses the aws_shutdown_callback_options,
    /// you must call release() to avoid leaking memory.
    func getCShutdownOptions() -> aws_shutdown_callback_options {
        var shutdown_options = aws_shutdown_callback_options()
        shutdown_options.shutdown_callback_fn = { rawValue in
            guard let rawValue = rawValue else {
                return
            }
            let shutdownCallbackOptions = Unmanaged<ShutdownCallbackCore>.fromOpaque(rawValue).takeRetainedValue()
            shutdownCallbackOptions.shutdownCallback()
        }
        shutdown_options.shutdown_callback_user_data = Unmanaged<ShutdownCallbackCore>.passRetained(self).toOpaque()
        return shutdown_options
    }

    func release() {
        Unmanaged<ShutdownCallbackCore>.passUnretained(self).release()
    }

    /// Calling this function performs a manual retain on the ShutdownCallbackCore.
    /// and returns aws_credentials_provider_shutdown_options. When the shutdown finally fires,
    /// it will manually release ShutdownCallbackCore.
    ///
    /// If you fail to create something that uses the aws_credentials_provider_shutdown_options,
    /// you must call release() to avoid leaking memory.
    func getCredentialProviderShutdownOptions() -> aws_credentials_provider_shutdown_options {
        var shutdown_options = aws_credentials_provider_shutdown_options()

        shutdown_options.shutdown_callback = { rawValue in
            guard let rawValue = rawValue else {
                return
            }
            let shutdownCallbackOptions = Unmanaged<ShutdownCallbackCore>.fromOpaque(rawValue).takeRetainedValue()
            shutdownCallbackOptions.shutdownCallback()
        }
        shutdown_options.shutdown_user_data = Unmanaged<ShutdownCallbackCore>.passRetained(self).toOpaque()
        return shutdown_options
    }

    /// Calling this function performs a manual retain on the ShutdownCallbackCore.
    /// and returns aws_imds_client_shutdown_options. When the shutdown finally fires,
    /// it will manually release ShutdownCallbackCore.
    ///
    /// If you fail to create something that uses the aws_imds_client_shutdown_options,
    /// you must call release() to avoid leaking memory.
    func getIMDSClientShutdownOptions() -> aws_imds_client_shutdown_options {
        var shutdown_options = aws_imds_client_shutdown_options()

        shutdown_options.shutdown_callback = { rawValue in
            guard let rawValue = rawValue else {
                return
            }
            let shutdownCallbackOptions = Unmanaged<ShutdownCallbackCore>.fromOpaque(rawValue).takeRetainedValue()
            shutdownCallbackOptions.shutdownCallback()
        }
        shutdown_options.shutdown_user_data = Unmanaged<ShutdownCallbackCore>.passRetained(self).toOpaque()
        return shutdown_options
    }
}
