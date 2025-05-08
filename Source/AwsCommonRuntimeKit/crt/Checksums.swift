//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCChecksums

import struct Foundation.Data

extension Data {

  /// Computes the CRC32 over data.
  /// - Parameter previousCrc32:  Pass 0 in the previousCrc32 parameter as an initial value unless continuing to update a running crc in a subsequent call.
  public func computeCRC32(previousCrc32: UInt32 = 0) -> UInt32 {
    self.withUnsafeBytes { bufferPointer in
      return aws_checksums_crc32_ex(
        bufferPointer.baseAddress?.assumingMemoryBound(to: UInt8.self),
        count,
        previousCrc32)
    }
  }

  /// Computes the crc32c over data.
  /// - Parameter previousCrc32c:  Pass 0 in the previousCrc32c parameter as an initial value unless continuing to update a running crc in a subsequent call.
  public func computeCRC32C(previousCrc32c: UInt32 = 0) -> UInt32 {
    self.withUnsafeBytes { bufferPointer in
      return aws_checksums_crc32c_ex(
        bufferPointer.baseAddress?.assumingMemoryBound(to: UInt8.self),
        count,
        previousCrc32c)
    }
  }

  /// Computes the CRC64NVME over data.
  /// - Parameter previousCrc64Nvme:  Pass 0 in the previousCrc64Nvme parameter as an initial value unless continuing to update a running crc in a subsequent call.
  public func computeCRC64Nvme(previousCrc64Nvme: UInt64 = 0) -> UInt64 {
    self.withUnsafeBytes { bufferPointer in
      return aws_checksums_crc64nvme_ex(
        bufferPointer.baseAddress?.assumingMemoryBound(to: UInt8.self),
        count,
        previousCrc64Nvme)
    }
  }

}
