//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import AwsCCommon

struct AWSDate {
    let rawValue: UnsafeMutablePointer<aws_date_time>
    let timestamp: String? = nil
    let epochMs: Int64
    let epochS: Double? = nil
    
    init(epochMs: Int64) {
        self.epochMs = epochMs
        self.rawValue = UnsafeMutablePointer<aws_date_time>.allocate(capacity: 1)
        aws_date_time_init_epoch_millis(rawValue, UInt64(epochMs))
    }
    
    func now() {
        aws_date_time_init_now(rawValue)
    }

}

