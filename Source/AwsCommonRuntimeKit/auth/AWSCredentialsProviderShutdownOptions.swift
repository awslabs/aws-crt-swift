//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

class AWSCredentialsProviderShutdownOptions {
    typealias ShutDownCallback = () -> Void
    public let rawValue: UnsafeMutablePointer<aws_credentials_provider_shutdown_options>
    public let shutDownCallback: ShutDownCallback

    public init(shutDownCallback: @escaping ShutDownCallback) {
        let swiftPointer = UnsafeMutablePointer<AWSCredentialsProviderShutdownOptions>.allocate(capacity: 1)
        let cPointer = UnsafeMutablePointer<aws_credentials_provider_shutdown_options>.allocate(capacity: 1)
        defer {
            swiftPointer.deallocate()
            cPointer.deallocate()
        }
        cPointer.pointee = aws_credentials_provider_shutdown_options(shutdown_callback: { userData in

                   let pointer = userData?.bindMemory(to: AWSCredentialsProviderShutdownOptions.self, capacity: 1)
                   defer {
                       pointer?.deallocate()
                   }
                   pointer?.pointee.shutDownCallback()

               }, shutdown_user_data: swiftPointer)
        self.shutDownCallback = shutDownCallback
        self.rawValue = cPointer
    }
}
