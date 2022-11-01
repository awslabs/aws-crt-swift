//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo

public final class ClientBootstrap {
    let rawValue: UnsafeMutablePointer<aws_client_bootstrap>
    var enableBlockingShutdown: Bool = false

    public init(eventLoopGroup elg: EventLoopGroup,
                hostResolver: HostResolver,
                allocator: Allocator = defaultAllocator,
                shutdownCallback: ShutdownCallback? = nil) throws {
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        let shutdownOptions = shutdownCallbackCore.getRetainedShutdownOptions()
        guard let rawValue = (hostResolver.config.withCPointer { hostResolverConfigPointer in
            var options = aws_client_bootstrap_options()
            options.event_loop_group = elg.rawValue
            options.host_resolver = hostResolver.rawValue
            options.host_resolution_config = hostResolverConfigPointer
            options.on_shutdown_complete = shutdownOptions.shutdown_callback_fn
            options.user_data = shutdownOptions.shutdown_callback_user_data
            return aws_client_bootstrap_new(allocator.rawValue, &options)
        }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    deinit {
        aws_client_bootstrap_release(rawValue)
    }
}
