//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

/// This is just a wrapper for aws_retry_token which user can not create themself but pass around once acquired.
public class CRTAWSRetryToken {
    let rawValue: UnsafeMutablePointer<aws_retry_token>

    init(rawValue: UnsafeMutablePointer<aws_retry_token>) {
        self.rawValue = rawValue
    }

    deinit {
        aws_retry_token_release(rawValue)
    }
}
