//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo
import Foundation

public final class ClientBootstrap {
    let rawValue: UnsafeMutablePointer<aws_client_bootstrap>
    var enableBlockingShutdown: Bool = false

    public init(eventLoopGroup elg: EventLoopGroup,
                hostResolver: HostResolver,
                shutDownCallbackOptions: ShutDownCallbackOptions? = nil,
                allocator: Allocator = defaultAllocator) throws {
        shutDownCallbackOptions?.retain()
        var options = aws_client_bootstrap_options(
            event_loop_group: elg.rawValue,
            host_resolver: hostResolver.rawValue,
            host_resolution_config: hostResolver.config,
            on_shutdown_complete: shutDownCallbackOptions?.rawValue.pointee.shutdown_callback_fn,
            user_data: shutDownCallbackOptions?.rawValue.pointee.shutdown_callback_user_data
        )
        guard let rawValue = aws_client_bootstrap_new(allocator.rawValue, &options) else {
            throw CRTError(errorCode: aws_last_error())
        }

        self.rawValue = rawValue
    }

    deinit {
        aws_client_bootstrap_release(rawValue)
    }
}
