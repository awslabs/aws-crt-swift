//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import struct Foundation.Data
import AwsCChecksums

extension Data {
    
    /// Computes the CRC32 over data.
    /// - Parameter previousCrc32:  Pass 0 in the previousCrc32 parameter as an initial value unless continuing to update a running crc in a subsequent call.
    public func crc32(previousCrc32: UInt32 = 0) -> UInt32 {
        self.withUnsafeBytes { bufferPointer in
            if let ptr = bufferPointer.baseAddress?.assumingMemoryBound(to: UInt8.self) {
                return aws_checksums_crc32(ptr, Int32(count), previousCrc32)
            }
            return 0
        }
    }
    
    /// Computes the crc32c over data.
    /// - Parameter previousCrc32c:  Pass 0 in the previousCrc32c parameter as an initial value unless continuing to update a running crc in a subsequent call.
    public func crc32c(previousCrc32c: UInt32 = 0) -> UInt32 {
        self.withUnsafeBytes { bufferPointer in
            if let ptr = bufferPointer.baseAddress?.assumingMemoryBound(to: UInt8.self) {
               return aws_checksums_crc32c(ptr, Int32(count), previousCrc32c)
            }
            return 0
        }
    }
    
}
