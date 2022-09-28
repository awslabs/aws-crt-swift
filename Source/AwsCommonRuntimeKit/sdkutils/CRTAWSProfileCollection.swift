//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils

public class CRTAWSProfileCollection {
    var rawValue: OpaquePointer

    public init?(fromFile path: String,
                 source: CRTAWSProfileSourceType,
                 allocator: Allocator = defaultAllocator)
    {
        var finalizedPath = path
        if path.hasPrefix("~"),
           let homeDirectory = aws_get_home_directory(allocator.rawValue),
           let homeDirectoryString = String(awsString: homeDirectory)
        {
            finalizedPath = homeDirectoryString + path.dropFirst()
        }
        let awsString = AWSString(finalizedPath, allocator: allocator)
        guard let profilePointer = aws_profile_collection_new_from_file(allocator.rawValue,
                                                                        awsString.rawValue,
                                                                        source.rawValue)
        else {
            return nil
        }
        rawValue = profilePointer
    }

    public init(fromBuffer buffer: ByteBuffer,
                source: CRTAWSProfileSourceType,
                allocator: Allocator = defaultAllocator)
    {
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
        rawValue = aws_profile_collection_new_from_buffer(allocator.rawValue,
                                                          pointer,
                                                          source.rawValue)
    }

    public init(configProfileCollection: CRTAWSProfileCollection,
                credentialProfileCollection: CRTAWSProfileCollection,
                source _: CRTAWSProfileSourceType,
                allocator: Allocator = defaultAllocator)
    {
        rawValue = aws_profile_collection_new_from_merge(allocator.rawValue,
                                                         configProfileCollection.rawValue,
                                                         credentialProfileCollection.rawValue)
    }

    public func getProfile(name: String, allocator: Allocator = defaultAllocator) -> CRTAWSProfile? {
        let awsString = AWSString(name, allocator: allocator)
        guard let profilePointer = aws_profile_collection_get_profile(rawValue,
                                                                      awsString.rawValue)
        else {
            return nil
        }
        return CRTAWSProfile(rawValue: profilePointer)
    }

    public var profileCount: Int {
        aws_profile_collection_get_profile_count(rawValue)
    }

    deinit {
        aws_profile_collection_destroy(rawValue)
    }
}
