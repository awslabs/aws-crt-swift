//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public struct HostAddress {
    public var host: String
    public var address: String
    public var recordType: AddressRecordType

    init(hostAddress: aws_host_address) {
        self.host = String(awsString: hostAddress.host)!
        self.address = String(awsString: hostAddress.address)!
        self.recordType = AddressRecordType(rawValue: hostAddress.record_type)
    }

    public init(
        host: String,
        address: String,
        recordType: AddressRecordType = .typeA
    ) {
        self.host = host
        self.address = address
        self.recordType = recordType
    }
}
