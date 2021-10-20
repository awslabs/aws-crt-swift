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
        self.marketPlaceProductCodes = instanceInfo.marketplace_product_codes.toStringArray()
        self.availabilityZone = instanceInfo.availability_zone.toString() ?? ""
        self.privateIp = instanceInfo.private_ip.toString() ?? ""
        self.version = instanceInfo.version.toString() ?? ""
        self.instanceId = instanceInfo.instance_id.toString() ?? ""
        self.billingProducts = instanceInfo.billing_products.toStringArray()
        self.instanceType = instanceInfo.instance_type.toString() ?? ""
        self.accountId = instanceInfo.account_id.toString() ?? ""
        self.imageId = instanceInfo.image_id.toString() ?? ""
        self.pendingTime = AWSDate(rawValue: instanceInfo.pending_time)
        self.architecture = instanceInfo.architecture.toString() ?? ""
        self.kernelId = instanceInfo.kernel_id.toString() ?? ""
        self.ramDiskId = instanceInfo.ramdisk_id.toString() ?? ""
        self.region = instanceInfo.region.toString() ?? ""
  
    }
}
