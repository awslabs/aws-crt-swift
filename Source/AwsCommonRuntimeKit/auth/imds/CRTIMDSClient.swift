//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCAuth
// TODO: rename file name
public class IMDSClient {
    let rawValue: OpaquePointer
    let allocator: Allocator
    public init(bootstrap: ClientBootstrap,
                retryStrategy: CRTAWSRetryStrategy,
                protocolVersion: CRTIMDSProtocolVersion = CRTIMDSProtocolVersion.version2,
                shutdownCallback: ShutdownCallback? = nil,
                allocator: Allocator = defaultAllocator) throws {
        self.allocator = allocator
        let shutdownCallbackCore = ShutdownCallbackCore(shutdownCallback)
        let shutdownOptions = shutdownCallbackCore.getRetainedIMDSClientShutdownOptions()
        var imdsOptions = aws_imds_client_options()
        imdsOptions.shutdown_options = shutdownOptions
        imdsOptions.bootstrap = bootstrap.rawValue
        imdsOptions.retry_strategy = retryStrategy.rawValue
        imdsOptions.imds_version = protocolVersion.rawValue
        guard let rawValue = aws_imds_client_new(allocator.rawValue, &imdsOptions) else {
            shutdownCallbackCore.release()
            throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    /// Queries a generic resource (string) from the ec2 instance metadata document
    ///
    /// - Parameters:
    ///    - resourcePath: `String` path of the resource to query
    public func getResource(resourcePath: String) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(resourcePath: resourcePath, client: self, continuation: continuation)
        }
    }

    /// Gets the ami id of the ec2 instance from the instance metadata document
    public func getAmiId() async throws -> String {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(client: self, continuation: continuation, functionPointer: aws_imds_client_get_ami_id)
        })
    }

    /// Gets the ami launch index of the ec2 instance from the instance metadata document
    public func getAmiLaunchIndex() async throws -> String {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(client: self,
                                                       continuation: continuation,
                                                       functionPointer: aws_imds_client_get_ami_launch_index)
        })
    }

    /// Gets the ami manifest path of the ec2 instance from the instance metadata document
    public func getAmiManifestPath() async throws -> String {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(client: self,
                                                       continuation: continuation,
                                                       functionPointer: aws_imds_client_get_ami_manifest_path)
        })
    }

    /// Gets the instance-action of the ec2 instance from the instance metadata document
    public func getInstanceAction() async throws -> String {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(client: self, continuation: continuation, functionPointer: aws_imds_client_get_instance_action)
        })
    }

    /// Gets the instance id of the ec2 instance from the instance metadata document
    public func getInstanceId() async throws -> String {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(client: self, continuation: continuation, functionPointer: aws_imds_client_get_instance_id)
        })
    }

    /// Gets the instance type of the ec2 instance from the instance metadata document
    public func getInstanceType() async throws -> String {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(client: self, continuation: continuation, functionPointer: aws_imds_client_get_instance_type)
        })
    }

    /// Gets the mac address of the ec2 instance from the instance metadata document
    public func getMacAddress() async throws -> String {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(client: self, continuation: continuation, functionPointer: aws_imds_client_get_mac_address)
        })
    }

    /// Gets the private ip address of the ec2 instance from the instance metadata document
    public func getPrivateIpAddress() async throws -> String {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(client: self,
                                                       continuation: continuation,
                                                       functionPointer: aws_imds_client_get_private_ip_address)
        })
    }

    /// Gets the availability zone of the ec2 instance from the instance metadata document
    public func getAvailabilityZone() async throws -> String {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(client: self,
                                                       continuation: continuation,
                                                       functionPointer: aws_imds_client_get_availability_zone)
        })
    }

    /// Gets the product codes of the ec2 instance from the instance metadata document
    public func getProductCodes() async throws -> String {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(client: self, continuation: continuation, functionPointer: aws_imds_client_get_product_codes)
        })
    }

    /// Gets the public key of the ec2 instance from the instance metadata document
    public func getPublicKey() async throws -> String {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(client: self, continuation: continuation, functionPointer: aws_imds_client_get_public_key)
        })
    }

    /// Gets the ramdisk id of the ec2 instance from the instance metadata document
    public func getRamDiskId() async throws -> String {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(client: self, continuation: continuation, functionPointer: aws_imds_client_get_ramdisk_id)
        })
    }

    /// Gets the reservation id of the ec2 instance from the instance metadata document
    public func getReservationId() async throws -> String {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(client: self, continuation: continuation, functionPointer: aws_imds_client_get_reservation_id)
        })
    }

    /// Gets the attached iam role of the ec2 instance from the instance metadata document
    public func getAttachedIAMRole() async throws -> String {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(client: self, continuation: continuation, functionPointer: aws_imds_client_get_attached_iam_role)
        })
    }

    /// Gets the user data of the ec2 instance from the instance metadata document
    public func getUserData() async throws -> String {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(client: self, continuation: continuation, functionPointer: aws_imds_client_get_user_data)
        })
    }

    /// Gets the signature of the ec2 instance from the instance metadata document
    public func getInstanceSignature() async throws -> String {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceContinuation) in
            IMDSClientCore<String>.getRetainedResource(client: self, continuation: continuation, functionPointer: aws_imds_client_get_instance_signature)
        })
    }


    /// Gets the list of ancestor ami ids of the ec2 instance from the instance metadata document
    public func getAncestorAmiIDs() async throws -> [String]? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceListContinuation) in
            IMDSClientCore<[String]>.getRetainedResourcesList(client: self, continuation: continuation, functionPointer: aws_imds_client_get_ancestor_ami_ids)
        })
    }

    /// Gets the list of the security groups of the ec2 instance from the instance metadata document
    public func getSecurityGroups() async throws -> [String]? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceListContinuation) in
            IMDSClientCore<[String]>.getRetainedResourcesList(client: self, continuation: continuation, functionPointer: aws_imds_client_get_security_groups)
        })
    }

    /// Gets the list of block device mappings of the ec2 instance from the instance metadata document
    public func getBlockDeviceMapping() async throws -> [String]? {
        return try await withCheckedThrowingContinuation({ (continuation: ResourceListContinuation) in
            IMDSClientCore<[String]>.getRetainedResourcesList(client: self, continuation: continuation, functionPointer: aws_imds_client_get_block_device_mapping)
        })
    }

    /// Gets temporary credentials based on the attached iam role of the ec2 instance
    ///
    /// - Parameters:
    ///    - iamRoleName: iam role name to get temporary credentials through
    public func getCredentials(iamRoleName: String) async throws -> AwsCredentials {
        return try await withCheckedThrowingContinuation({ (continuation: CredentialsContinuation) in
            iamRoleName.withByteCursor { iamRoleNameCursor in
               IMDSClientCore<AwsCredentials>.getRetainedCredentials(iamRoleName: iamRoleName,
                                                                  client: self,
                                                                  continuation: continuation)
            }
        })
    }

    /// Gets the iam profile information of the ec2 instance from the instance metadata document
    public func getIAMProfile() async throws -> CRTIAMProfile {
        return try await withCheckedThrowingContinuation({ (continuation: GetIMDSProfileContinuation) in
            IMDSClientCore<CRTIAMProfile>.getRetainedIAMProfile(client: self, continuation: continuation)
        })
    }

    /// Gets the instance information data block of the ec2 instance from the instance metadata document
    ///
    /// - Parameters:
    ///    - callbackData: The `CRTIMDSClientInstanceCallbackData` object with an async callback
    public func getInstanceInfo() async throws -> CRTIMDSInstanceInfo {
        return try await withCheckedThrowingContinuation({ (continuation: GetInstanceInfo) in
           IMDSClientCore<CRTIMDSInstanceInfo>.getRetainedInstanceInfo(client: self, continuation: continuation)
        })
    }

    deinit {
        aws_imds_client_release(rawValue)
    }
}
