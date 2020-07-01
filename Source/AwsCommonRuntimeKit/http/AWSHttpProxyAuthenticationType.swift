//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public enum AWSHttpProxyAuthenticationType {
    case none
    case basic
}

extension AWSHttpProxyAuthenticationType {
    var rawValue: aws_http_proxy_authentication_type {
        switch self {
        case .none:  return AWS_HPAT_NONE
        case .basic: return AWS_HPAT_BASIC
        }
    }
}

extension aws_http_proxy_authentication_type {
    var awsHttpProxyAuthenticationType: AwsHttpProxyAuthenticationType! {
        switch self.rawValue {
        case AWS_HPAT_BASIC.rawValue: return AwsHttpProxyAuthenticationType.basic
        case AWS_HPAT_NONE.rawValue:  return AwsHttpProxyAuthenticationType.none
        default:
            assertionFailure("Unknown aws_socket_domain: \(String(describing: self))")
            return nil // <- Makes compiler happy, but we'd have halted right before reaching here
        }
    }
}