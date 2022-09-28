//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public typealias GenerateRandom = () -> UInt64

public struct CRTExponentialBackoffRetryOptions {
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
}
