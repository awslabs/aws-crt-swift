//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
import Foundation

public struct CRTIMDSInstanceInfo {
    public var marketPlaceProductCodes: [String]
    public var availabilityZone: String?
    public var privateIp: String?
    public var version: String?
    public var instanceId: String?
    public var billingProducts: [String]
    public var instanceType: String?
    public var accountId: String?
    public var imageId: String?
    public var pendingTime: Date
    public var architecture: String?
    public var kernelId: String?
    public var ramDiskId: String?
    public var region: String?

    init(instanceInfo: aws_imds_instance_info) {
        self.marketPlaceProductCodes = instanceInfo.marketplace_product_codes.byteCursorListToStringArray()
        self.availabilityZone = instanceInfo.availability_zone.toString()
        self.privateIp = instanceInfo.private_ip.toString()
        self.version = instanceInfo.version.toString()
        self.instanceId = instanceInfo.instance_id.toString()
        self.billingProducts = instanceInfo.billing_products.byteCursorListToStringArray()
        self.instanceType = instanceInfo.instance_type.toString()
        self.accountId = instanceInfo.account_id.toString()
        self.imageId = instanceInfo.image_id.toString()
        self.pendingTime = instanceInfo.pending_time.toDate()
        self.architecture = instanceInfo.architecture.toString()
        self.kernelId = instanceInfo.kernel_id.toString()
        self.ramDiskId = instanceInfo.ramdisk_id.toString()
        self.region = instanceInfo.region.toString()
    }
}
