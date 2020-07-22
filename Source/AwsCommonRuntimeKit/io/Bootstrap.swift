//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo

public final class ClientBootstrap {
  internal let rawValue: UnsafeMutablePointer<aws_client_bootstrap>

  public init(eventLoopGroup elg: EventLoopGroup, hostResolver: HostResolver, allocator: Allocator = defaultAllocator) throws {
    var options = aws_client_bootstrap_options(
            event_loop_group: &elg.rawValue,
            host_resolver: &hostResolver.rawValue,
            host_resolution_config: nil,
            on_shutdown_complete: nil,
            user_data: nil
    )
    guard let rawValue = aws_client_bootstrap_new(allocator.rawValue, &options) else {
      throw AwsCommonRuntimeError()
    }
    self.rawValue = rawValue
  }

  deinit {
    aws_client_bootstrap_release(self.rawValue)
  }
}
