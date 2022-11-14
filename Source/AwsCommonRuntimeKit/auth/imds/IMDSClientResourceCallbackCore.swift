//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCAuth

typealias ResourceContinuation = CheckedContinuation<String, Error>
class IMDSClientCore {
    let continuation: ResourceContinuation

    init(continuation: ResourceContinuation) {
        self.continuation = continuation
    }

    private func getRetainedSelf() -> UnsafeMutableRawPointer {
        return Unmanaged<IMDSClientCore>.passRetained(self).toOpaque()
    }

    public static func getRetainedResource(resourcePath: String, client: IMDSClient, continuation: ResourceContinuation) {
        let core = IMDSClientCore(continuation: continuation)
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

    private func release() {
        Unmanaged.passUnretained(self).release()
    }
}

private func resourceCallback(_ byteBuf: UnsafePointer<aws_byte_buf>?,
                              _ errorCode: Int32,
                              _ userData: UnsafeMutableRawPointer!) {
    let imdsClientCore = Unmanaged<IMDSClientCore>.fromOpaque(userData).takeRetainedValue()
    if errorCode != AWS_OP_SUCCESS {
        imdsClientCore.continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
        return
    }

    // Success
    //TODO: do we need to make a copy?
    imdsClientCore.continuation.resume(returning: String(cString: byteBuf!.pointee.buffer))
}
