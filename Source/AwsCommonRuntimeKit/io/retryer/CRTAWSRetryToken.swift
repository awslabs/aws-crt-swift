//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public final class CRTAWSRetryToken {
    var rawValue: UnsafeMutablePointer<aws_retry_token>

    public init(rawValue: UnsafeMutablePointer<aws_retry_token>,
                allocator: Allocator = defaultAllocator) {
        self.rawValue = rawValue
    }

}
