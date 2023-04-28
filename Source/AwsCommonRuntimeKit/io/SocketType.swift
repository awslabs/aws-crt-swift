//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public enum SocketType {
    /// A streaming socket sends reliable messages over a two-way connection.
    /// This means TCP when used with IPV4/6, and Unix domain sockets, when used with
    /// AWS_SOCKET_LOCAL
    case stream
    /// A datagram socket is connectionless and sends unreliable messages.
    /// This means UDP when used with IPV4/6.
    /// LOCAL sockets are not compatible with DGRAM.
    case datagram
}

extension SocketType {
  var rawValue: aws_socket_type {
        switch self {
        case .stream: return AWS_SOCKET_STREAM
        case .datagram: return AWS_SOCKET_DGRAM
        }
    }
}
