//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCIo

public struct CRTStandardRetryOptions: CStruct {
    /// capacity for partitions. Defaults to 500
    public var initialBucketCapacity: Int
    public var exponentialBackoffRetryOptions: CRTExponentialBackoffRetryOptions

    public init(initialBucketCapacity: Int = 500, exponentialBackoffRetryOptions: CRTExponentialBackoffRetryOptions) {
        self.initialBucketCapacity = initialBucketCapacity
        self.exponentialBackoffRetryOptions = exponentialBackoffRetryOptions
    }

    typealias RawType = aws_standard_retry_options
    func withCStruct<Result>(_ body: (aws_standard_retry_options) -> Result) -> Result {
        var cStandardRetryOptions = aws_standard_retry_options()
        cStandardRetryOptions.initial_bucket_capacity = initialBucketCapacity
        return exponentialBackoffRetryOptions.withCStruct { cExponentialBackoffRetryOptions in
            cStandardRetryOptions.backoff_retry_options = cExponentialBackoffRetryOptions
            return body(cStandardRetryOptions)
        }
    }
}
