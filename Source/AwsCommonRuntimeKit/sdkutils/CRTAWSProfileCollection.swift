//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils

public class CRTAWSProfileCollection {
    var rawValue: OpaquePointer

    public init(fromFile path: String,
                source: CRTAWSProfileSourceType,
                allocator: Allocator = defaultAllocator) {
        let awsString = AWSString(path, allocator: allocator)
        self.rawValue = aws_profile_collection_new_from_file(allocator.rawValue,
                                                             awsString.rawValue,
                                                             source.rawValue)
    }

    public init(fromBuffer buffer: ByteBuffer,
                source: CRTAWSProfileSourceType,
                allocator: Allocator = defaultAllocator) {
        var byteArray = buffer.toByteArray()
        let byteCount = byteArray.count
        let byteBuf = byteArray.withUnsafeMutableBufferPointer { pointer -> aws_byte_buf in
            let byteBuf = aws_byte_buf(len: byteCount,
                                buffer: pointer.baseAddress,
                                capacity: byteCount,
                                allocator: allocator.rawValue)
            return byteBuf
        }
        let pointer: UnsafePointer<aws_byte_buf> = fromPointer(ptr: byteBuf)
        self.rawValue = aws_profile_collection_new_from_buffer(allocator.rawValue,
                                                               pointer,
                                                               source.rawValue)

    }

    public init(configProfileCollection: CRTAWSProfileCollection,
                credentialProfileCollection: CRTAWSProfileCollection,
                source: CRTAWSProfileSourceType,
                allocator: Allocator = defaultAllocator) {
        self.rawValue = aws_profile_collection_new_from_merge(allocator.rawValue,
                                                              configProfileCollection.rawValue,
                                                              credentialProfileCollection.rawValue)
    }

    public func getProfile(name: String, profileCollection: CRTAWSProfileCollection, allocator: Allocator = defaultAllocator) -> CRTAWSProfile? {
        let awsString = AWSString(name, allocator: allocator)
        guard let profilePointer = aws_profile_collection_get_profile(profileCollection.rawValue,
                                                                      awsString.rawValue) else {
            return nil
        }
        return CRTAWSProfile(rawValue: profilePointer)
    }

    public var profileCount: Int {
        return aws_profile_collection_get_profile_count(rawValue)
    }

    deinit {
        aws_profile_collection_destroy(rawValue)
    }
}
