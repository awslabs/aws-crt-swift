//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCSdkUtils
import struct Foundation.Data

public class ProfileCollection {
    var rawValue: OpaquePointer

    /// Create a new profile collection by parsing a file with the specified path
    public init(fromFile path: String,
                source: ProfileSourceType,
                allocator: Allocator = defaultAllocator) throws {
        var finalizedPath = path
        if path.hasPrefix("~"),
           let homeDirectory = aws_get_home_directory(allocator.rawValue),
           let homeDirectoryString = String(awsString: homeDirectory) {
            finalizedPath = homeDirectoryString + path.dropFirst()
        }
        let awsString = AWSString(finalizedPath, allocator: allocator)
        guard let profilePointer = aws_profile_collection_new_from_file(allocator.rawValue,
                                                                        awsString.rawValue,
                                                                        source.rawValue)
        else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = profilePointer
    }

    /// Create a new profile collection by parsing text in a buffer. Primarily for testing.
    init(fromData data: Data,
         source: ProfileSourceType,
         allocator: Allocator = defaultAllocator) throws {
        let byteCount = data.count
        guard let rawValue  = (data.withUnsafeBytes { rawBufferPointer in
            var byteBuf = aws_byte_buf_from_array(rawBufferPointer.baseAddress, byteCount)
            return aws_profile_collection_new_from_buffer(allocator.rawValue,
                                                          &byteBuf,
                                                          source.rawValue)

        }) else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }

        self.rawValue = rawValue
    }

    /// Create a new profile collection by merging a config-file-based profile
    /// collection and a credentials-file-based profile collection
    public init(configProfileCollection: ProfileCollection,
                credentialProfileCollection: ProfileCollection,
                allocator: Allocator = defaultAllocator) throws {
        guard let rawValue = aws_profile_collection_new_from_merge(allocator.rawValue,
                                                                   configProfileCollection.rawValue,
                                                                   credentialProfileCollection.rawValue)
        else {
            throw CommonRunTimeError.crtError(.makeFromLastError())
        }
        self.rawValue = rawValue
    }

    /// Retrieves a reference to a profile with the specified name, if it exists, from the profile collection
    public func getProfile(name: String, allocator: Allocator = defaultAllocator) -> Profile? {
        let awsString = AWSString(name, allocator: allocator)
        guard let profilePointer = aws_profile_collection_get_profile(self.rawValue,
                                                                      awsString.rawValue)
        else {
            return nil
        }
        return Profile(rawValue: profilePointer, collection: self)
    }

    /// Returns how many profiles a collection holds
    public var profileCount: Int {
        return aws_profile_collection_get_profile_count(rawValue)
    }

    deinit {
        aws_profile_collection_destroy(rawValue)
    }
}
