//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo

public struct ClientBootstrapOptions: CStructWithShutdownOptions {
    public var eventLoopGroup: EventLoopGroup
    public var hostResolver: HostResolver
    public var shutdownCallback: ShutdownCallback?
    var enableBlockingShutdown: Bool = false

    public init(eventLoopGroup: EventLoopGroup,
                hostResolver: HostResolver,
                shutdownCallback: ShutdownCallback? = nil) throws {
        self.eventLoopGroup = eventLoopGroup
        self.hostResolver = hostResolver
        self.shutdownCallback = shutdownCallback
    }

    typealias RawType = aws_client_bootstrap_options
    func withCStruct<Result>(shutdownOptions: aws_shutdown_callback_options, _ body: (aws_client_bootstrap_options) -> Result
    ) -> Result {
        var options = aws_client_bootstrap_options()
        options.event_loop_group = eventLoopGroup.rawValue
        options.host_resolver = hostResolver.rawValue
        options.on_shutdown_complete = shutdownOptions.shutdown_callback_fn
        options.user_data = shutdownOptions.shutdown_callback_user_data
        return hostResolver.config.withCPointer { hostResolverConfigPointer in
            options.host_resolution_config = hostResolverConfigPointer
            return body(options)
        }
    }
}
