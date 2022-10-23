//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo

public class HostResolutionConfig {

    let rawValue: UnsafeMutablePointer<aws_host_resolution_config>
    let allocator: Allocator
    public init(maxTTL: Int, allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
        rawValue = allocator.allocate(capacity: 1)
        rawValue.pointee.max_ttl = maxTTL
        rawValue.pointee.impl = aws_default_dns_resolve
    }

    deinit {
        allocator.release(rawValue)
    }
}
