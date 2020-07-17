//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCIo

private let defaultSocketTimeMsec = UInt32(3_000)

public struct SocketOptions {
    internal var rawValue: aws_socket_options
    
    public init(socketType: SocketType = .stream) {
        self.rawValue = aws_socket_options(
            type: socketType.rawValue,
            domain: AWS_SOCKET_IPV4,
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

public enum SocketDomain {
    case ipv4
    case ipv6
    case local
}

extension SocketDomain: RawRepresentable, CaseIterable {
    public static var allCases: [SocketDomain] {
        return [.ipv4, .ipv6, .local]
    }
    public init(rawValue: aws_socket_domain) {
        let value = Self.allCases.first { $0.rawValue == rawValue }
        self = value ?? .ipv4
    }
    public var rawValue: aws_socket_domain {
        switch self {
        case .ipv4:  return AWS_SOCKET_IPV4
        case .ipv6:  return AWS_SOCKET_IPV6
        case .local: return AWS_SOCKET_LOCAL
        }
    }
}


public enum SocketType {
    case datagram
    case stream
}

extension SocketType: RawRepresentable, CaseIterable {
    public static var allCases: [SocketType] {
        return [.datagram, .stream]
    }
    public init(rawValue: aws_socket_type) {
        let value = Self.allCases.first(where: {$0.rawValue == rawValue})
        self = value ?? .datagram
    }
    public var rawValue: aws_socket_type {
        switch self {
        case .datagram: return AWS_SOCKET_DGRAM
        case .stream:   return AWS_SOCKET_STREAM
        }
    }
}

