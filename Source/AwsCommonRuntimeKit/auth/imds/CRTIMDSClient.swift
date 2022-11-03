//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth

// swiftlint:disable opening_brace
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
    public func getResource(resourcePath: String) async throws -> String? {
        return try await withCheckedThrowingContinuation { (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_resource_async(rawValue, resourcePath.awsByteCursor, resourceCallback, pointer)
        }
    }

    /// Gets the ami id of the ec2 instance from the instance metadata document
    public func getAmiId() async throws -> String? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_ami_id(rawValue, resourceCallback, pointer)
        })
    }

    /// Gets the ami launch index of the ec2 instance from the instance metadata document
    public func getAmiLaunchIndex() async throws -> String? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_ami_launch_index(rawValue, resourceCallback, pointer)
        })
    }

    /// Gets the ami manifest path of the ec2 instance from the instance metadata document
    public func getAmiManifestPath() async throws -> String? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_ami_manifest_path(rawValue, resourceCallback, pointer)
        })
    }

    /// Gets the list of ancestor ami ids of the ec2 instance from the instance metadata document
    public func getAncestorAmiIDs() async throws -> [String]? {
        return try await withCheckedThrowingContinuation({ (continuation: ArrayContinuation) in
            let callbackData = CRTIMDSClientArrayCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_ancestor_ami_ids(rawValue, arrayCallback, pointer)
        })
    }

    /// Gets the instance-action of the ec2 instance from the instance metadata document
    public func getInstanceAction() async throws -> String? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_instance_action(rawValue, resourceCallback, pointer)
        })
    }

    /// Gets the instance id of the ec2 instance from the instance metadata document
    public func getInstanceId() async throws -> String? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_instance_id(rawValue, resourceCallback, pointer)
        })
    }

    /// Gets the instance type of the ec2 instance from the instance metadata document
    public func getInstanceType() async throws -> String? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_instance_type(rawValue, resourceCallback, pointer)
        })
    }

    /// Gets the mac address of the ec2 instance from the instance metadata document
    public func getMacAddress() async throws -> String? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_mac_address(rawValue, resourceCallback, pointer)
        })
    }

    /// Gets the private ip address of the ec2 instance from the instance metadata document
    public func getPrivateIpAddress() async throws -> String? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_private_ip_address(rawValue, resourceCallback, pointer)
        })
    }

    /// Gets the availability zone of the ec2 instance from the instance metadata document
    public func getAvailabilityZone() async throws -> String? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_availability_zone(rawValue, resourceCallback, pointer)
        })
    }

    /// Gets the product codes of the ec2 instance from the instance metadata document
    public func getProductCodes() async throws -> String? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_product_codes(rawValue, resourceCallback, pointer)
        })
    }

    /// Gets the public key of the ec2 instance from the instance metadata document
    public func getPublicKey() async throws -> String? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_public_key(rawValue, resourceCallback, pointer)
        })
    }

    /// Gets the ramdisk id of the ec2 instance from the instance metadata document
    public func getRamDiskId() async throws -> String? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_ramdisk_id(rawValue, resourceCallback, pointer)
        })
    }

    /// Gets the reservation id of the ec2 instance from the instance metadata document
    public func getReservationId() async throws -> String? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_reservation_id(rawValue, resourceCallback, pointer)
        })
    }

    /// Gets the list of the security groups of the ec2 instance from the instance metadata document
    public func getSecurityGroups() async throws -> [String]? {
        return try await withCheckedThrowingContinuation({ (continuation: ArrayContinuation) in
            let callbackData = CRTIMDSClientArrayCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_security_groups(rawValue, arrayCallback, pointer)
        })
    }

    /// Gets the list of block device mappings of the ec2 instance from the instance metadata document
    public func getBlockDeviceMapping() async throws -> [String]? {
        return try await withCheckedThrowingContinuation({ (continuation: ArrayContinuation) in
            let callbackData = CRTIMDSClientArrayCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_block_device_mapping(rawValue, arrayCallback, pointer)
        })
    }

    /// Gets the attached iam role of the ec2 instance from the instance metadata document
    public func getAttachedIAMRole() async throws -> String? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_attached_iam_role(rawValue, resourceCallback, pointer)
        })
    }

    /// Gets temporary credentials based on the attached iam role of the ec2 instance
    ///
    /// - Parameters:
    ///    - callbackData: The `CRTCredentialsCallbackData` object with an async callback
    public func getCredentials(iamRoleName: String) async throws -> CRTCredentials {
        return try await withCheckedThrowingContinuation({ (continuation: CredentialsContinuation) in
            getCredentialsFromCRT(iamRoleName: iamRoleName, continuation: continuation)
        })
    }

    public func getCredentialsFromCRT(iamRoleName: String, continuation: CredentialsContinuation) {
        let callbackData = CRTCredentialsProviderCallbackData(continuation: continuation)
        let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
        aws_imds_client_get_credentials(
            rawValue,
            iamRoleName.awsByteCursor,
            { credentialsPointer, errorCode, userData in
                guard let userData = userData else {
                    return
                }
                let pointer = userData.assumingMemoryBound(to: CRTCredentialsProviderCallbackData.self)
                
                let error = AWSError(errorCode: errorCode)
                if errorCode == 0,
                   let credentialsPointer = credentialsPointer,
                   let crtCredentials = CRTCredentials(rawValue: credentialsPointer) {
                    pointer.pointee.continuation?.resume(returning: crtCredentials)
                } else {
                    pointer.pointee.continuation?.resume(throwing: CRTError.crtError(error))
                }
                pointer.deinitializeAndDeallocate()
            },
            pointer
        )
    }

    /// Gets the iam profile information of the ec2 instance from the instance metadata document
    public func getIAMProfile() async throws -> CRTIAMProfile? {
        return try await withCheckedThrowingContinuation({ (continuation: IAMProfileContinuation) in
            let callbackData = CRTIMDSClientIAMProfileCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_iam_profile(rawValue, { profilePointer, errorCode, userData in
                guard let userData = userData else {
                    return
                }
                let pointer = userData.assumingMemoryBound(to: CRTIMDSClientIAMProfileCallbackData.self)
                let error = AWSError(errorCode: errorCode)
                guard let profilePointer = profilePointer else {
                    pointer.pointee.continuation?.resume(throwing: CRTError.crtError(error))
                    pointer.deinitializeAndDeallocate()
                    return
                }
                let profile = CRTIAMProfile(pointer: profilePointer)
                pointer.pointee.continuation?.resume(returning: profile)
                pointer.deinitializeAndDeallocate()
            }, pointer)
        })

    }

    /// Gets the user data of the ec2 instance from the instance metadata document
    public func getUserData() async throws -> String? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_user_data(rawValue, resourceCallback, pointer)
        })
    }

    /// Gets the signature of the ec2 instance from the instance metadata document
    public func getInstanceSignature() async throws -> String? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            let callbackData = CRTIMDSClientResourceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_instance_signature(rawValue, resourceCallback, pointer)
        })
    }

    /// Gets the instance information data block of the ec2 instance from the instance metadata document
    ///
    /// - Parameters:
    ///    - callbackData: The `CRTIMDSClientInstanceCallbackData` object with an async callback
    public func getInstanceInfo() async throws -> CRTIMDSInstanceInfo? {
        return try await withCheckedThrowingContinuation({ (continuation: InstanceInfoContinuation) in
            let callbackData = CRTIMDSClientInstanceCallbackData(continuation: continuation)
            let pointer: UnsafeMutableRawPointer = fromPointer(ptr: callbackData)
            aws_imds_client_get_instance_info(rawValue, { instancePointer, errorCode, userData in
                guard let userData = userData else {
                    return
                }
                let pointer = userData.assumingMemoryBound(to: CRTIMDSClientInstanceCallbackData.self)
                let error = AWSError(errorCode: errorCode)
                guard let instancePointer = instancePointer else {
                    pointer.pointee.continuation?.resume(throwing: CRTError.crtError(error))
                    pointer.deinitializeAndDeallocate()
                    return
                }
                pointer.pointee.continuation?.resume(returning: CRTIMDSInstanceInfo(pointer: instancePointer))
                pointer.deinitializeAndDeallocate()
            }, pointer)
        })
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

private func resourceCallback(_ byteBuf: UnsafePointer<aws_byte_buf>?,
                              _ errorCode: Int32,
                              _ userData: UnsafeMutableRawPointer?) {
    guard let userData = userData else {
        return
    }

    let pointer = userData.assumingMemoryBound(to: CRTIMDSClientResourceCallbackData.self)
    let error = AWSError(errorCode: errorCode)
    guard let byteBuf = byteBuf else {

        pointer.pointee.continuation?.resume(throwing: CRTError.crtError(error))
        pointer.deinitializeAndDeallocate()
        return
    }

    let byteCursor = aws_byte_cursor_from_buf(byteBuf)
    pointer.pointee.continuation?.resume(returning: byteCursor.toString())
    pointer.deinitializeAndDeallocate()
}

private func arrayCallback(_ arrayListPointer: UnsafePointer<aws_array_list>?,
                           _ errorCode: Int32,
                           _ userData: UnsafeMutableRawPointer?) {
    guard let userData = userData else {
        return
    }
    let pointer = userData.assumingMemoryBound(to: CRTIMDSClientArrayCallbackData.self)
    let error = AWSError(errorCode: errorCode)
    if error.errorCode != 0 {
        pointer.pointee.continuation?.resume(throwing: CRTError.crtError(error))
    }
    let amiIds = arrayListPointer?.pointee.toStringArray()

    pointer.pointee.continuation?.resume(returning: amiIds)
    pointer.deinitializeAndDeallocate()
}
