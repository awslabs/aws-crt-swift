//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo
import Foundation

public final class ClientBootstrap {
  let rawValue: UnsafeMutablePointer<aws_client_bootstrap>
  var enableBlockingShutdown: Bool = false
  let shutDownSemaphore: DispatchSemaphore

  public init(eventLoopGroup elg: EventLoopGroup,
              hostResolver: HostResolver,
              allocator: Allocator = defaultAllocator) throws {

    let hostResolverPointer = UnsafeMutablePointer<aws_host_resolver>.allocate(capacity: 1)
    hostResolverPointer.initialize(to: hostResolver.rawValue.pointee)

    let hostResolverConfigPointer = UnsafeMutablePointer<aws_host_resolution_config>.allocate(capacity: 1)
    hostResolverConfigPointer.initialize(to: hostResolver.config)
    shutDownSemaphore = DispatchSemaphore(value: 1)
    let clientBootstrapCallbackData = ClientBootstrapCallbackData(shutDownSemaphore: shutDownSemaphore)

    let callbackDataPointer = UnsafeMutablePointer<ClientBootstrapCallbackData>.allocate(capacity: 1)
    callbackDataPointer.initialize(to: clientBootstrapCallbackData)

    var options = aws_client_bootstrap_options(
        event_loop_group: elg.rawValue,
            host_resolver: hostResolverPointer,
            host_resolution_config: hostResolverConfigPointer,
            on_shutdown_complete: { userData in

                let pointer = userData?.assumingMemoryBound(to: ClientBootstrapCallbackData.self)
                defer { pointer?.deinitializeAndDeallocate() }
                pointer?.pointee.shutDownSemaphore.signal()
                if let shutDownComplete = pointer?.pointee.onShutDownComplete {
                    shutDownComplete()
                }
            },
            user_data: callbackDataPointer
    )
    guard let rawValue = aws_client_bootstrap_new(allocator.rawValue, &options) else {
      throw AwsCommonRuntimeError()
    }

    self.rawValue = rawValue
  }

    func enableBlockingShutDown() {
        enableBlockingShutdown = true
    }

  deinit {
    aws_client_bootstrap_release(self.rawValue)
    if enableBlockingShutdown {
        shutDownSemaphore.wait()
    }
  }
}
