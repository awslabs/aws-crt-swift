//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo

public typealias ScheduleRetryContinuation = CheckedContinuation<CRTAWSRetryToken, Error>
public struct CRTScheduleRetryCallbackData {
    //public typealias OnRetryReady = (CRTAWSRetryToken?, CRTError) -> Void
    public var continuation: ScheduleRetryContinuation?
    public let allocator: Allocator

    public init(allocator: Allocator = defaultAllocator,
                continuation: ScheduleRetryContinuation? = nil) {
        self.continuation = continuation
        self.allocator = allocator
    }
}
