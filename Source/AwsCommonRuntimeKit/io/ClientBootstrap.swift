//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo

public class ClientBootstrap {
    let rawValue: UnsafeMutablePointer<aws_client_bootstrap>

    public init(eventLoopGroup elg: EventLoopGroup,
                hostResolver: HostResolver,
                shutdownCallback: ShutdownCallback? = nil) throws {
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        let shutdownOptions = shutdownCallbackCore.getRetainedShutdownOptions()
        let getRawValue: () -> UnsafeMutablePointer<aws_client_bootstrap>? = {
            withUnsafePointer(to: hostResolver.getHostResolutionConfig()) { hostResolutionConfigPointer in
                var options = aws_client_bootstrap_options()
                options.event_loop_group = elg.rawValue
                options.host_resolver = hostResolver.rawValue
                options.host_resolution_config = hostResolutionConfigPointer
                options.on_shutdown_complete = shutdownOptions.shutdown_callback_fn
                options.user_data = shutdownOptions.shutdown_callback_user_data
                return aws_client_bootstrap_new(allocator.rawValue, &options)
            }
        }

        guard let rawValue = getRawValue() else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        self.rawValue = rawValue
    }

    deinit {
        aws_client_bootstrap_release(rawValue)
    }
}
