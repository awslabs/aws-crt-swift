//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation

import struct Foundation.Date
import struct Foundation.Data
import struct Foundation.TimeInterval
import AwsCCal
import AwsCChecksums

extension Data {
    
    /// Computes the CRC32 over data.
    /// - Parameter previousCrc32:  Pass 0 in the previousCrc32 parameter as an initial value unless continuing to update a running crc in a subsequent call.
    public func crc32(previousCrc32: UInt32 = 0) -> UInt32 {
        self.withUnsafeBytes { bufferPointer in
            return aws_checksums_crc32(bufferPointer.baseAddress, Int32(count) , previousCrc32)
        }
    }
    
    /// Computes the crc32c over data.
    /// - Parameter previousCrc32c:  Pass 0 in the previousCrc32c parameter as an initial value unless continuing to update a running crc in a subsequent call.
    public func crc32c(previousCrc32c: UInt32 = 0) -> UInt32 {
        self.withUnsafeBytes { bufferPointer in
            return aws_checksums_crc32c(bufferPointer.baseAddress, Int32(count) , previousCrc32c)
        }
    }
    
    
}
