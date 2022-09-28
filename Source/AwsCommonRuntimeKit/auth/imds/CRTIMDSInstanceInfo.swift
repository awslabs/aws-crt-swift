//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

public struct CRTIMDSInstanceInfo {
    public let marketPlaceProductCodes: [String]
    public let availabilityZone: String
    public let privateIp: String
    public let version: String
    public let instanceId: String
    public let billingProducts: [String]
    public let instanceType: String
    public let accountId: String
    public let imageId: String
    public let pendingTime: AWSDate
    public let architecture: String
    public let kernelId: String
    public let ramDiskId: String
    public let region: String

    init(pointer: UnsafePointer<aws_imds_instance_info>) {
        let instanceInfo = pointer.pointee
        marketPlaceProductCodes = instanceInfo.marketplace_product_codes.toStringArray()
        availabilityZone = instanceInfo.availability_zone.toString() ?? ""
        privateIp = instanceInfo.private_ip.toString() ?? ""
        version = instanceInfo.version.toString() ?? ""
        instanceId = instanceInfo.instance_id.toString() ?? ""
        billingProducts = instanceInfo.billing_products.toStringArray()
        instanceType = instanceInfo.instance_type.toString() ?? ""
        accountId = instanceInfo.account_id.toString() ?? ""
        imageId = instanceInfo.image_id.toString() ?? ""
        pendingTime = AWSDate(rawValue: instanceInfo.pending_time)
        architecture = instanceInfo.architecture.toString() ?? ""
        kernelId = instanceInfo.kernel_id.toString() ?? ""
        ramDiskId = instanceInfo.ramdisk_id.toString() ?? ""
        region = instanceInfo.region.toString() ?? ""
    }
}
