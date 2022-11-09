//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo

public struct HostResolutionConfig: CStruct {

    public var maxTTL: Int
    public init(maxTTL: Int) {
        self.maxTTL = maxTTL
    }

    typealias RawType = aws_host_resolution_config
    func withCStruct<Result>(_ body: (aws_host_resolution_config) -> Result) -> Result {
        var cHostResolutionConfig = aws_host_resolution_config()
        cHostResolutionConfig.max_ttl = maxTTL
        cHostResolutionConfig.impl = aws_default_dns_resolve
        return body(cHostResolutionConfig)
    }
}
