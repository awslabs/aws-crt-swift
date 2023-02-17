//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public struct HostAddress: CStruct {
    /// Address type (ipv6, ipv4 etc)
    public let addressType: HostAddressType

    /// The resolved numerical address represented as a String
    /// passing this string to pton(), for example, should correctly return the numerical representation
    public let address: String

    /// host name of the resolved address
    public let hostName: String

    /// Service record. Currently, unused largely because we use Http, but this may change as we add more protocols.
    public let service: String? = nil

    let allocator: Allocator
    let expiry: UInt64
    let useCount: Int
    let connectionFailureCount: Int
    let weight: UInt8

    init(hostAddress: aws_host_address) {
        hostName = String(awsString: hostAddress.host)!
        address = String(awsString: hostAddress.address)!
        addressType = HostAddressType(rawValue: hostAddress.record_type)
        allocator = hostAddress.allocator
        expiry = hostAddress.expiry
        useCount = hostAddress.use_count
        connectionFailureCount = hostAddress.connection_failure_count
        weight = hostAddress.weight

    }

    typealias RawType = aws_host_address

    func withCStruct<Result>(_ body: (aws_host_address) -> Result) -> Result {
        let cAddress = AWSString(address, allocator: allocator)
        let cHostName = AWSString(hostName, allocator: allocator)

        var cHostAddress = aws_host_address()
        cHostAddress.record_type = addressType.rawValue
        cHostAddress.address = UnsafePointer(cAddress.rawValue)
        cHostAddress.host = UnsafePointer(cHostName.rawValue)
        cHostAddress.allocator = allocator.rawValue
        cHostAddress.expiry = expiry
        cHostAddress.use_count = useCount
        cHostAddress.connection_failure_count = connectionFailureCount
        cHostAddress.weight = weight
        return body(cHostAddress)
    }
}

public struct HostResolverArguments {

    /// Host name to resolve
    public var hostName: String

    /// Service record. Currently unused largely because we use Http, but this may
    /// change as we add more protocols.
    public var service: String?

    public init(hostName: String, service: String? = nil) {
        self.hostName = hostName
        self.service = service
    }
}
