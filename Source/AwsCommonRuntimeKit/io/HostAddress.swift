//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public struct HostAddress {
    public var host: String?
    public var address: String?
    public var recordType: AddressRecordType
    public var expiry: UInt64
    public var useCount: Int
    public var connectionFailureCount: Int
    public var weight: UInt8

    init(hostAddress: aws_host_address) {
        self.host = String(awsString: hostAddress.host)
        self.address = String(awsString: hostAddress.address)
        self.recordType = AddressRecordType(rawValue: hostAddress.record_type)
        self.expiry = hostAddress.expiry
        self.useCount = hostAddress.use_count
        self.connectionFailureCount = hostAddress.connection_failure_count
        self.weight = hostAddress.weight
    }

    public init(host: String? = nil,
                address:String? = nil,
                recordType: AddressRecordType = .typeA,
                expiry: UInt64 = 0,
                useCount: Int = 0,
                connectionFailureCount: Int = 0,
                weight: UInt8 = 0) {
        self.host = host
        self.address = address
        self.recordType = recordType
        self.expiry = expiry
        self.useCount = useCount
        self.connectionFailureCount = connectionFailureCount
        self.weight = weight
    }
}
