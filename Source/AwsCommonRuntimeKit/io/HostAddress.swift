//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public struct HostAddress {
    let host: String?
    let address: String?
    let recordType: AddressRecordType
    let expiry: UInt64
    let useCount: Int
    let connectionFailureCount: Int
    let weight: UInt8

    init(hostAddress: aws_host_address) {
        host = String(awsString: hostAddress.host)
        address = String(awsString: hostAddress.address)
        recordType = AddressRecordType(rawValue: hostAddress.record_type)
        expiry = hostAddress.expiry
        useCount = hostAddress.use_count
        connectionFailureCount = hostAddress.connection_failure_count
        weight = hostAddress.weight
    }

    init() {
        host = nil
        address = nil
        recordType = .typeA
        expiry = 0
        useCount = 0
        connectionFailureCount = 0
        weight = 0
    }
}
