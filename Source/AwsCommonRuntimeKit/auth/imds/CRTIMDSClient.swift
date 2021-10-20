//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
import Foundation

public class CRTIMDSClient {
    let rawValue: OpaquePointer
    
    public init(options: CRTIMDSClientOptions, allocator: Allocator = defaultAllocator) {
        let shutDownOptions = CRTIMDSClient.setUpShutDownOptions(shutDownOptions: options.shutDownOptions)
        var imdsOptions = aws_imds_client_options(shutdown_options: shutDownOptions,
                                                  bootstrap: options.bootstrap.rawValue,
                                                  retry_strategy: options.retryStrategy.rawValue,
                                                  imds_version: options.protocolVersion.rawValue,
                                                  function_table: nil)
        self.rawValue = aws_imds_client_new(allocator.rawValue, &imdsOptions)
    }
    /// Queries a generic resource (string) from the ec2 instance metadata document
    ///
    /// - Parameters:
    ///    - resourcePath: `String` path of the resource to query
    ///    - callbackData: The `CRTIMDSClientResourceCallbackData` object with an async callback
    public func getResource(resourcePath: String, callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_resource_async(rawValue, resourcePath.awsByteCursor, resourceCallback, pointer)
    }
    
    public func getAmiId(callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_ami_id(rawValue, resourceCallback, pointer)
    }
    
    public func getAmiLaunchIndex(callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_ami_launch_index(rawValue, resourceCallback, pointer)
    }
    
    public func getAmiManifestPath(callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_ami_manifest_path(rawValue, resourceCallback, pointer)
    }
    
    public func getAncestorAmiIDs(callbackData: CRTIMDSClientArrayCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_ancestor_ami_ids(rawValue, arrayCallback, pointer)
    }
    
    public func getInstanceAction(callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_instance_action(rawValue, resourceCallback, pointer)
    }
    
    public func getInstanceId(callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_instance_id(rawValue, resourceCallback, pointer)
    }
    
    public func getInstanceType(callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_instance_type(rawValue, resourceCallback, pointer)
    }
    
    public func getMacAddress(callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_mac_address(rawValue, resourceCallback, pointer)
    }
    
    public func getPrivateIpAddress(callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_private_ip_address(rawValue, resourceCallback, pointer)
    }
    
    /// Gets the availability zone of the ec2 instance from the instance metadata document
    public func getAvailabilityZone(callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_availability_zone(rawValue, resourceCallback, pointer)
    }
    
    /// Gets the product codes of the ec2 instance from the instance metadata document
    public func getProductCodes(callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_product_codes(rawValue, resourceCallback, pointer)
    }
    
    /// Gets the public key of the ec2 instance from the instance metadata document
    public func getPublicKey(callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_public_key(rawValue, resourceCallback, pointer)
    }
    
    /// Gets the ramdisk id of the ec2 instance from the instance metadata document
    public func getRamDiskId(callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_ramdisk_id(rawValue, resourceCallback, pointer)
    }
    
    /// Gets the reservation id of the ec2 instance from the instance metadata document
    public func getReservationId(callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_reservation_id(rawValue, resourceCallback, pointer)
    }
    
    /// Gets the list of the security groups of the ec2 instance from the instance metadata document
    public func getSecurityGroups(callbackData: CRTIMDSClientArrayCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_security_groups(rawValue, arrayCallback, pointer)
    }
    
    /// Gets the list of block device mappings of the ec2 instance from the instance metadata document
    public func getBlockDeviceMapping(callbackData: CRTIMDSClientArrayCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_block_device_mapping(rawValue, arrayCallback, pointer)
    }
    
    /// Gets the attached iam role of the ec2 instance from the instance metadata document
    public func getAttachedIAMRole(callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_attached_iam_role(rawValue, resourceCallback, pointer)
    }
    
    /// Gets the user data of the ec2 instance from the instance metadata document
    public func getUserData(callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_user_data(rawValue, resourceCallback, pointer)
    }
    
    /// Gets the signature of the ec2 instance from the instance metadata document
    public func getInstanceSignature(callbackData: CRTIMDSClientResourceCallbackData) {
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_instance_signature(rawValue, resourceCallback, pointer)
    }
    
    static func setUpShutDownOptions(shutDownOptions: CRTIDMSClientShutdownOptions?)
    -> aws_imds_client_shutdown_options {

        let pointer: UnsafeMutablePointer<CRTIDMSClientShutdownOptions>? = fromOptionalPointer(ptr: shutDownOptions)
        let shutDownOptionsC = aws_imds_client_shutdown_options(shutdown_callback: { userData in
            guard let userData = userData else {
                return
            }
            let pointer = userData.assumingMemoryBound(to: CRTIDMSClientShutdownOptions.self)
            pointer.pointee.shutDownCallback()
            pointer.deinitializeAndDeallocate()
        }, shutdown_user_data: pointer)

        return shutDownOptionsC
    }
    
    deinit {
        aws_imds_client_release(rawValue)
    }
}

private func resourceCallback(_ byteBuf :UnsafePointer<aws_byte_buf>?,
                              _ errorCode: Int32,
                              _ userData:  UnsafeMutableRawPointer?) {
    guard let userData = userData else {
        return
    }
    
    let pointer = userData.assumingMemoryBound(to: CRTIMDSClientResourceCallbackData.self)
    let error = AWSError(errorCode: errorCode)
    let byteCursor = aws_byte_cursor_from_buf(byteBuf)

    pointer.pointee.onResourceResolved(byteCursor.toString(), CRTError.crtError(error))
    pointer.deinitializeAndDeallocate()
}

private func arrayCallback(_ arrayListPointer :UnsafePointer<aws_array_list>?,
                           _ errorCode: Int32,
                           _ userData:  UnsafeMutableRawPointer?) {
    guard let userData = userData else {
        return
    }
    let pointer = userData.assumingMemoryBound(to: CRTIMDSClientArrayCallbackData.self)
    let error = AWSError(errorCode: errorCode)
    
    let length = aws_array_list_length(arrayListPointer)
    var amiIds: [String] = Array(repeating: "", count: length)

    for index  in 0..<length {
        var address: UnsafeMutableRawPointer! = nil
        aws_array_list_get_at_ptr(arrayListPointer, &address, index)
        amiIds[index] = address.bindMemory(to: String.self, capacity: 1).pointee
    }

    pointer.pointee.onArrayResolved(amiIds, CRTError.crtError(error))
    pointer.deinitializeAndDeallocate()
}
