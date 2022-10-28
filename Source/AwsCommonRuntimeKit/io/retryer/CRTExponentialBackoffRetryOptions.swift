//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo
public typealias GenerateRandom = () -> UInt64

public struct CRTExponentialBackoffRetryOptions: CStruct {
    let eventLoopGroup: EventLoopGroup
    let maxRetries: Int
    let backOffScaleFactor: UInt32
    let generateRandom: GenerateRandom?
    let jitterMode: CRTExponentialBackoffJitterMode

    public init(eventLoopGroup: EventLoopGroup,
                maxRetries: Int = 10,
                backOffScaleFactor: UInt32 = 25,
                jitterMode: CRTExponentialBackoffJitterMode = .default,
                generateRandom: GenerateRandom? = nil) {
        self.eventLoopGroup = eventLoopGroup
        self.maxRetries = maxRetries
        self.backOffScaleFactor = backOffScaleFactor
        self.jitterMode = jitterMode
        self.generateRandom = generateRandom
    }

    typealias RawType = aws_exponential_backoff_retry_options
    func withCStruct<Result>(_ body: (aws_exponential_backoff_retry_options) -> Result) -> Result {
        var cExponentialBackoffRetryOptions = aws_exponential_backoff_retry_options()
        cExponentialBackoffRetryOptions.el_group = eventLoopGroup.rawValue
        cExponentialBackoffRetryOptions.max_retries = maxRetries
        cExponentialBackoffRetryOptions.backoff_scale_factor_ms = backOffScaleFactor
        cExponentialBackoffRetryOptions.jitter_mode = jitterMode.rawValue
        //TODO: fix generate random
        return body(cExponentialBackoffRetryOptions)
    }
}
