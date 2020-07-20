//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCAuth

public final class Credentials {
    
    let rawValue: OpaquePointer
    
    public init(accessKey: String,
                secret: String,
                sessionToken: String,
                expirationTimeout: Int,
                allocator: Allocator = defaultAllocator) {
        self.rawValue = aws_credentials_new(allocator.rawValue,
                                            accessKey.awsByteCursor,
                                            secret.awsByteCursor,
                                            sessionToken.awsByteCursor, UInt64(expirationTimeout))
    }
    
    
    deinit {
        aws_credentials_release(rawValue)
    }
}
