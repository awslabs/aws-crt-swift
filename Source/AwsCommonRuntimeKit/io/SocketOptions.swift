//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public struct SocketOptions {
    var rawValue: aws_socket_options
    let defaultSocketTimeMsec = UInt32(3_000)

    public init(socketType: SocketType = .stream) {
        self.rawValue = aws_socket_options(
            type: socketType.rawValue,
            domain: SocketDomain.ipv4.rawValue,
            connect_timeout_ms: defaultSocketTimeMsec,
            keep_alive_interval_sec: 0,
            keep_alive_timeout_sec: 0,
            keep_alive_max_failed_probes: 0,
            keepalive: false
        )
    }

    public var connectTimeoutMs: UInt32 {
        get { return self.rawValue.connect_timeout_ms }
        set(value) { self.rawValue.connect_timeout_ms = value }
    }

    public var keepAlive: Bool {
        get { return self.rawValue.keepalive }
        set(value) { self.rawValue.keepalive = value }
    }

    public var keepaliveIntervalSec: UInt16 {
        get { return self.rawValue.keep_alive_interval_sec }
        set(value) { self.rawValue.keep_alive_interval_sec = value }
    }

    public var keepaliveMaxFailedProbes: UInt16 {
        get { return self.rawValue.keep_alive_max_failed_probes }
        set(value) { self.rawValue.keep_alive_max_failed_probes = value }
    }

    public var keepaliveTimeoutSec: UInt16 {
        get { return self.rawValue.keep_alive_timeout_sec }
        set(value) { self.rawValue.keep_alive_timeout_sec = value }
    }

    public var socketDomain: SocketDomain {
        get { return SocketDomain(rawValue: self.rawValue.domain) }
        set(value) { self.rawValue.domain = value.rawValue }
    }

    public var socketType: SocketType {
        get { return SocketType(rawValue: self.rawValue.type) }
        set(value) { self.rawValue.type = value.rawValue }
    }
}
