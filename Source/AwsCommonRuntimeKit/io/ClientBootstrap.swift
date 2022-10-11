//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo
import Foundation

public final class ClientBootstrap {
    let rawValue: UnsafeMutablePointer<aws_client_bootstrap>
    var enableBlockingShutdown: Bool = false
    let callbackData: ClientBootstrapCallbackData?

    /// Take a reference to keep it alive
    private let elg: EventLoopGroup
    private let hostResolver: HostResolver
    public init(eventLoopGroup elg: EventLoopGroup,
                hostResolver: HostResolver,
                callbackData: ClientBootstrapCallbackData? = nil,
                allocator: Allocator = defaultAllocator) throws {
        self.elg = elg
        self.hostResolver = hostResolver
        self.callbackData = callbackData
        let callbackDataPointer: UnsafeMutablePointer<ClientBootstrapCallbackData>? = fromOptionalPointer(ptr: callbackData)

        var options = aws_client_bootstrap_options(
            event_loop_group: elg.rawValue,
            host_resolver: hostResolver.rawValue,
            host_resolution_config: hostResolver.config,
            on_shutdown_complete: { userData in
                guard let userData = userData else { return }

                let pointer = userData.assumingMemoryBound(to: ClientBootstrapCallbackData.self)
                defer { pointer.deinitializeAndDeallocate() }
                pointer.pointee.onShutDownComplete(pointer.pointee.shutDownSemaphore)

            },
            user_data: callbackDataPointer
        )
        guard let rawValue = aws_client_bootstrap_new(allocator.rawValue, &options) else {
            throw CRTError(errorCode: aws_last_error())
        }

        self.rawValue = rawValue
    }

    func enableBlockingShutDown() {
        enableBlockingShutdown = true
    }

    deinit {
        aws_client_bootstrap_release(rawValue)
        if enableBlockingShutdown {
            callbackData?.shutDownSemaphore.wait()
        }
    }
}
