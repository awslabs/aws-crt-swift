//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCAuth

//can only be implemented by a class
protocol CredentialsProvider: AnyObject {
    var allocator : Allocator { get set }
    var rawValue: UnsafeMutablePointer<aws_credentials_provider> {get set}
    
    init(connection: UnsafeMutablePointer<aws_credentials_provider>, allocator: Allocator)
    
    func getCredentials(credentialCallBackData: CredentialProviderCallbackData) 
}
