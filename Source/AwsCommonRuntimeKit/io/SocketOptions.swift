//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

public class SocketOptions {
    var rawValue: UnsafeMutablePointer<aws_socket_options>
    private let defaultSocketTimeMsec = UInt32(3_000)
    private let allocator: Allocator
    public init(socketType: SocketType = .stream, allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
        self.rawValue = allocator.allocate(capacity: 1)
        rawValue.pointee.type = socketType.rawValue
        rawValue.pointee.domain = SocketDomain.ipv4.rawValue
        rawValue.pointee.connect_timeout_ms = defaultSocketTimeMsec
        rawValue.pointee.keepalive = false
    }

    public var connectTimeoutMs: UInt32 {
        get { return self.rawValue.pointee.connect_timeout_ms }
        set(value) { self.rawValue.pointee.connect_timeout_ms = value }
    }

    public var keepAlive: Bool {
        get { return self.rawValue.pointee.keepalive }
        set(value) { self.rawValue.pointee.keepalive = value }
    }

    public var keepaliveIntervalSec: UInt16 {
        get { return self.rawValue.pointee.keep_alive_interval_sec }
        set(value) { self.rawValue.pointee.keep_alive_interval_sec = value }
    }

    public var keepaliveMaxFailedProbes: UInt16 {
        get { return self.rawValue.pointee.keep_alive_max_failed_probes }
        set(value) { self.rawValue.pointee.keep_alive_max_failed_probes = value }
    }

    public var keepaliveTimeoutSec: UInt16 {
        get { return self.rawValue.pointee.keep_alive_timeout_sec }
        set(value) { self.rawValue.pointee.keep_alive_timeout_sec = value }
    }

    public var socketDomain: SocketDomain {
        get { return SocketDomain(rawValue: self.rawValue.pointee.domain) }
        set(value) { self.rawValue.pointee.domain = value.rawValue }
    }

    public var socketType: SocketType {
        get { return SocketType(rawValue: self.rawValue.pointee.type) }
        set(value) { self.rawValue.pointee.type = value.rawValue }
    }

    deinit {
        allocator.release(rawValue)
    }
}
