//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

public protocol CRTRetryOptions {
    /** capacity for partitions. Defaults to 500 */
    var initialBucketCapacity: Int { get set }
    var backOffRetryOptions: CRTExponentialBackoffRetryOptions { get set }
}
