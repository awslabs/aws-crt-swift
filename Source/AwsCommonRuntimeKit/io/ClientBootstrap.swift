//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo

public class ClientBootstrap {
    let rawValue: UnsafeMutablePointer<aws_client_bootstrap>

    public init(clientBootstrapOptions: ClientBootstrapOptions, allocator: Allocator = defaultAllocator) throws {
        let shutdownCallbackCore = ShutdownCallbackCore(clientBootstrapOptions.shutdownCallback)
        let shutdownOptions = shutdownCallbackCore.getRetainedShutdownOptions()
        guard let rawValue = (clientBootstrapOptions.withCPointer(shutdownOptions: shutdownOptions) { clientBootstrapOptionsPointer in
            return aws_client_bootstrap_new(allocator.rawValue, clientBootstrapOptionsPointer)
        }) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    public convenience init(eventLoopGroup: EventLoopGroup,
                            hostResolver: HostResolver,
                            allocator: Allocator = defaultAllocator,
                            shutdownCallback: ShutdownCallback? = nil) throws {
        try self.init(clientBootstrapOptions: ClientBootstrapOptions(eventLoopGroup: eventLoopGroup,
                                                                     hostResolver: hostResolver,
                                                                     shutdownCallback: shutdownCallback),
                      allocator: allocator)
    }

    deinit {
        aws_client_bootstrap_release(rawValue)
    }
}
