//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public struct SocketOptions: CStruct {
    public var socketType: SocketType
    public var socketDomain: SocketDomain
    public var connectTimeoutMs: UInt32
    public var keepaliveIntervalSec: UInt16
    public var keepaliveMaxFailedProbes: UInt16
    public var keepaliveTimeoutSec: UInt16
    public var keepAlive: Bool

    public init(socketType: SocketType = .stream,
                socketDomain: SocketDomain = SocketDomain.ipv4,
                connectTimeoutMs: UInt32 = 3_000,
                keepaliveIntervalSec: UInt16 = 0,
                keepaliveMaxFailedProbes: UInt16 = 0,
                keepaliveTimeoutSec: UInt16 = 0,
                keepAlive: Bool = false) {
        self.socketType = socketType
        self.socketDomain = socketDomain
        self.connectTimeoutMs = connectTimeoutMs
        self.keepaliveIntervalSec = keepaliveIntervalSec
        self.keepaliveMaxFailedProbes = keepaliveMaxFailedProbes
        self.keepaliveTimeoutSec = keepaliveTimeoutSec
        self.keepAlive = keepAlive
    }

    typealias RawType = aws_socket_options
    func withCStruct<Result>(_ body: (aws_socket_options) -> Result) -> Result {
        var cSocketOptions = aws_socket_options()
        cSocketOptions.type = socketType.rawValue
        cSocketOptions.domain = SocketDomain.ipv4.rawValue
        cSocketOptions.connect_timeout_ms = connectTimeoutMs
        cSocketOptions.keep_alive_interval_sec = keepaliveIntervalSec
        cSocketOptions.keep_alive_timeout_sec = keepaliveTimeoutSec
        cSocketOptions.keep_alive_max_failed_probes = keepaliveMaxFailedProbes
        cSocketOptions.keepalive = keepAlive
        return body(cSocketOptions)
    }
}
