//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

/// Direction to seek the stream. Current is currently not supported.
public enum StreamSeekType: UInt32 {
    /// Seek the stream starting from beginning
    case begin = 0
    /// Seek the stream of End.
    case end = 2
}
