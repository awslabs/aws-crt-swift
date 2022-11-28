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
        self.availabilityZone = instanceInfo.availability_zone.toOptionalString()
        self.privateIp = instanceInfo.private_ip.toOptionalString()
        self.version = instanceInfo.version.toOptionalString()
        self.instanceId = instanceInfo.instance_id.toOptionalString()
        self.billingProducts = instanceInfo.billing_products.byteCursorListToStringArray()
        self.instanceType = instanceInfo.instance_type.toOptionalString()
        self.accountId = instanceInfo.account_id.toOptionalString()
        self.imageId = instanceInfo.image_id.toOptionalString()
        self.pendingTime = instanceInfo.pending_time.toDate()
        self.architecture = instanceInfo.architecture.toOptionalString()
        self.kernelId = instanceInfo.kernel_id.toOptionalString()
        self.ramDiskId = instanceInfo.ramdisk_id.toOptionalString()
        self.region = instanceInfo.region.toOptionalString()
    }
}
