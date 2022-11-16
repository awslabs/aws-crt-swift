//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCAuth

typealias ResourceContinuation = CheckedContinuation<String, Error>
typealias ResourceListContinuation = CheckedContinuation<[String], Error>
typealias GetIMDSCredentialsContinuation = CheckedContinuation<AwsCredentials, Error>
typealias GetIMDSProfileContinuation = CheckedContinuation<CRTIAMProfile, Error>
typealias GetInstanceInfo = CheckedContinuation<CRTIMDSInstanceInfo, Error>

typealias CGetIMDSResourceFunctionPointer = (OpaquePointer?,
                                            (@convention(c) (UnsafePointer<aws_byte_buf>?, Int32, UnsafeMutableRawPointer?) -> Void)?,
                                            UnsafeMutableRawPointer?) -> Int32
typealias CGetIMDSResourceListFunctionPointer = (OpaquePointer?,
                                                (@convention(c) (UnsafePointer<aws_array_list>?, Int32, UnsafeMutableRawPointer?) -> Void)?,
                                                UnsafeMutableRawPointer?) -> Int32
class IMDSClientCore<T> {
    let continuation: CheckedContinuation<T, Error>

    init(continuation: CheckedContinuation<T, Error>) {
        self.continuation = continuation
    }

    private func getRetainedSelf() -> UnsafeMutableRawPointer {
        return Unmanaged<IMDSClientCore>.passRetained(self).toOpaque()
    }

    static func getRetainedResource(resourcePath: String,
                                    client: IMDSClient,
                                    continuation: ResourceContinuation) {
        let core = IMDSClientCore<String>(continuation: continuation)
        let retainedSelf = core.getRetainedSelf()
        resourcePath.withByteCursor { resourcePathCursor in
            if(aws_imds_client_get_resource_async(client.rawValue,
                                                  resourcePathCursor,
                                                  resourceCallback,
                                                  retainedSelf)) != AWS_OP_SUCCESS {

                core.release()
                continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
            }
        }
    }

    static func getRetainedResource(client: IMDSClient,
                                    continuation: ResourceContinuation,
                                    functionPointer: CGetIMDSResourceFunctionPointer) {
        let core = IMDSClientCore<String>(continuation: continuation)
        let retainedSelf = core.getRetainedSelf()
        if(functionPointer(client.rawValue,
                resourceCallback,
                retainedSelf)) != AWS_OP_SUCCESS {
            core.release()
            continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
        }
    }

    static func getRetainedResourcesList(client: IMDSClient,
                                         continuation: ResourceListContinuation,
                                         functionPointer: CGetIMDSResourceListFunctionPointer) {
        let core = IMDSClientCore<[String]>(continuation: continuation)
        let retainedSelf = core.getRetainedSelf()
        if(functionPointer(client.rawValue,
                resourceListCallback,
                retainedSelf)) != AWS_OP_SUCCESS {
            core.release()
            continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
        }
    }

    static func getRetainedCredentials(iamRoleName: String,
                                       client: IMDSClient,
                                       continuation: GetIMDSCredentialsContinuation) {
        let core = IMDSClientCore<AwsCredentials>(continuation: continuation)
        let retainedSelf = core.getRetainedSelf()
        iamRoleName.withByteCursor { iamRoleNameCursor in
            if(aws_imds_client_get_credentials(client.rawValue,
                    iamRoleNameCursor,
                    onGetCredentialsCallback,
                    retainedSelf)) != AWS_OP_SUCCESS {
                core.release()
                continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
            }
        }
    }

    static func getRetainedIAMProfile(client: IMDSClient,
                                      continuation: GetIMDSProfileContinuation) {
        let core = IMDSClientCore<CRTIAMProfile>(continuation: continuation)
        let retainedSelf = core.getRetainedSelf()
        if(aws_imds_client_get_iam_profile(client.rawValue, onGetIAMProfileCallback, retainedSelf)) != AWS_OP_SUCCESS {
            core.release()
            continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
        }
    }

    static func getRetainedInstanceInfo(client: IMDSClient,
                                        continuation: GetInstanceInfo) {
        let core = IMDSClientCore<CRTIMDSInstanceInfo>(continuation: continuation)
        let retainedSelf = core.getRetainedSelf()
        if(aws_imds_client_get_instance_info(client.rawValue, onGetInstanceInfoCallback, retainedSelf)) != AWS_OP_SUCCESS {
            core.release()
            continuation.resume(throwing: CommonRunTimeError.crtError(.makeFromLastError()))
        }
    }

    private func release() {
        Unmanaged.passUnretained(self).release()
    }
}

private func resourceCallback(_ byteBuf: UnsafePointer<aws_byte_buf>?,
                              _ errorCode: Int32,
                              _ userData: UnsafeMutableRawPointer!) {
    let imdsClientCore = Unmanaged<IMDSClientCore<String>>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        imdsClientCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    //TODO: test
    imdsClientCore.continuation.resume(returning: String(cString: byteBuf!.pointee.buffer))
}

private func resourceListCallback(_ arrayListPointer: UnsafePointer<aws_array_list>?,
                                  _ errorCode: Int32,
                                  _ userData: UnsafeMutableRawPointer!) {
    let imdsClientCore = Unmanaged<IMDSClientCore<[String]>>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        imdsClientCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    imdsClientCore.continuation.resume(returning: arrayListPointer!.pointee.byteCursorListToStringArray())
}

private func onGetCredentialsCallback(credentialsPointer: OpaquePointer?,
                                      errorCode: Int32,
                                      userData: UnsafeMutableRawPointer!) {
    let imdsClientCore = Unmanaged<IMDSClientCore<AwsCredentials>>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        imdsClientCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    let crtCredentials = AwsCredentials(rawValue: credentialsPointer!)
    imdsClientCore.continuation.resume(returning: crtCredentials)
}

private func onGetIAMProfileCallback(profilePointer: UnsafePointer<aws_imds_iam_profile>?,
                                     errorCode: Int32,
                                     userData: UnsafeMutableRawPointer!) {
    let imdsClientCore = Unmanaged<IMDSClientCore<CRTIAMProfile>>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        imdsClientCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    imdsClientCore.continuation.resume(returning: CRTIAMProfile(profile: profilePointer!.pointee))
}

private func onGetInstanceInfoCallback(infoPointer: UnsafePointer<aws_imds_instance_info>?,
                                       errorCode: Int32,
                                       userData: UnsafeMutableRawPointer!){
    let imdsClientCore = Unmanaged<IMDSClientCore<CRTIMDSInstanceInfo>>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        imdsClientCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    imdsClientCore.continuation.resume(returning: CRTIMDSInstanceInfo(instanceInfo: infoPointer!.pointee))
}
