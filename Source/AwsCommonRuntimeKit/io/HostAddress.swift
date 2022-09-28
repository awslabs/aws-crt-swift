//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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
        self.host = String(awsString: hostAddress.host)
        self.address = String(awsString: hostAddress.address)
        self.recordType = AddressRecordType(rawValue: hostAddress.record_type)
        self.expiry = hostAddress.expiry
        self.useCount = hostAddress.use_count
        self.connectionFailureCount = hostAddress.connection_failure_count
        self.weight = hostAddress.weight
    }

    init() {
        self.host = nil
        self.address = nil
        self.recordType = .typeA
        self.expiry = 0
        self.useCount = 0
        self.connectionFailureCount = 0
        self.weight = 0
    }
}
