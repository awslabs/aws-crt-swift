//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public struct HostAddress {
    /// Address type (ipv6, ipv4 etc)
    public let addressType: HostAddressType

    /// The resolved numerical address represented as a String
    /// passing this string to pton(), for example, should correctly return the numerical representation
    public let address: String

    /// host name of the resolved address
    public let hostName: String

    /// Service record. Currently, unused largely because we use Http, but this may change as we add more protocols.
    public let service: String? = nil

    var rawValue: aws_host_address

    init(hostAddress: aws_host_address) {
        self.hostName = String(awsString: hostAddress.host)!
        self.address = String(awsString: hostAddress.address)!
        self.addressType = HostAddressType(rawValue: hostAddress.record_type)
        self.rawValue = hostAddress
    }
}

public struct HostResolverArguments {

    /// Host name to resolve
    public var hostName: String

    /// Service record. Currently unused largely because we use Http, but this may
    /// change as we add more protocols.
    public var service: String? = nil

    public init(hostName: String, service: String? = nil) {
        self.hostName = hostName
        self.service = service
    }
}