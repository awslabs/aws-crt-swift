//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

//can only be implemented by a class
protocol CredentialsProvider: AnyObject {
    var allocator: Allocator { get set }
    var rawValue: UnsafeMutablePointer<aws_credentials_provider> {get set}

    init(credentialsProvider: UnsafeMutablePointer<aws_credentials_provider>, allocator: Allocator)

    func getCredentials(credentialCallbackData: CredentialProviderCallbackData)
}

extension CredentialsProvider {
    /// Retrieves credentials from a provider and returns them to the callback passed in.
    ///
    /// - Parameters:
    ///   - credentialCallbackData:  The `CredentialProviderCallbackData`options object.
    func getCredentials(credentialCallbackData: CredentialProviderCallbackData) {
        let pointer = UnsafeMutablePointer<CredentialProviderCallbackData>.allocate(capacity: 1)
        pointer.initialize(to: credentialCallbackData)
        aws_credentials_provider_get_credentials(rawValue, { (credentials, errorCode, userdata) -> Void in
            guard let userdata = userdata else {
                return
            }
            let pointer = userdata.assumingMemoryBound(to: CredentialProviderCallbackData.self)
            defer { pointer.deinitializeAndDeallocate() }
            pointer.pointee.onCredentialsResolved(Credentials(rawValue: credentials), errorCode)

        }, pointer)
    }
}
