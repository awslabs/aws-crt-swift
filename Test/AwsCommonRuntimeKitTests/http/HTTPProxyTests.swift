//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import AwsCAuth
import Foundation
@testable import AwsCommonRuntimeKit

class HTTPProxyTests: XCBaseTestCase {

    let HTTPProxyHost = ProcessInfo.processInfo.environment["AWS_TEST_HTTP_PROXY_HOST"]
    let HTTPProxyPort = ProcessInfo.processInfo.environment["AWS_TEST_HTTP_PROXY_PORT"]
    let HTTPSProxyHost = ProcessInfo.processInfo.environment["AWS_TEST_HTTPS_PROXY_HOST"]
    let HTTPSProxyPort = ProcessInfo.processInfo.environment["AWS_TEST_HTTPS_PROXY_PORT"]
    let HTTPProxyBasicHost = ProcessInfo.processInfo.environment["AWS_TEST_HTTP_PROXY_BASIC_HOST"]
    let HTTPProxyBasicPort = ProcessInfo.processInfo.environment["AWS_TEST_HTTP_PROXY_BASIC_PORT"]
    let HTTPProxyBasicAuthUsername = ProcessInfo.processInfo.environment["AWS_TEST_BASIC_AUTH_USERNAME"]
    let HTTPProxyBasicAuthPassword = ProcessInfo.processInfo.environment["AWS_TEST_BASIC_AUTH_PASSWORD"]
    let HTTPProxyTLSCertPath = ProcessInfo.processInfo.environment["AWS_TEST_TLS_CERT_PATH"]
    let HTTPProxyTLSKeyPath = ProcessInfo.processInfo.environment["AWS_TEST_TLS_KEY_PATH"]
    let HTTPProxyTLSRootCAPath = ProcessInfo.processInfo.environment["AWS_TEST_TLS_ROOT_CERT_PATH"]

    func testForwardNoAuth() async throws {
        try skipIfEnvironmentNotSetup()
        try await doProxyTest(type: ProxyTestType.forwarding, authType: .none)
    }

    func testLegacyHTTPNoAuth() async throws {
        try skipIfEnvironmentNotSetup()
        try await doProxyTest(type: ProxyTestType.legacyHTTP, authType: .none)
    }

    func testLegacyHTTPSNoAuth() async throws {
        try skipIfEnvironmentNotSetup()
        try await doProxyTest(type: ProxyTestType.legacyHTTPS, authType: .none)
    }

    func testTunnellingHTTPNoAuth() async throws {
        try skipIfEnvironmentNotSetup()
        try await doProxyTest(type: ProxyTestType.tunnelingHTTP, authType: .none)
    }

    func testTunnellingHTTPSNoAuth() async throws {
        try skipIfEnvironmentNotSetup()
        try await doProxyTest(type: ProxyTestType.tunnelingHTTPS, authType: .none)
    }

    func testTunnellingDoubleTLSNoAuth() async throws {
        try skipIfEnvironmentNotSetup()
        try await doProxyTest(type: ProxyTestType.tunnelingDoubleTLS, authType: .none)
    }


    func testForwardBasicAuth() async throws {
        try skipIfEnvironmentNotSetup()
        try await doProxyTest(type: ProxyTestType.forwarding, authType: .basic)
    }

    func testLegacyHTTPBasicAuth() async throws {
        try skipIfEnvironmentNotSetup()
        try await doProxyTest(type: ProxyTestType.legacyHTTP, authType: .basic)
    }

    func testLegacyHTTPSBasicAuth() async throws {
        try skipIfEnvironmentNotSetup()
        try await doProxyTest(type: ProxyTestType.legacyHTTPS, authType: .basic)
    }

    func testTunnellingHTTPBasicAuth() async throws {
        try skipIfEnvironmentNotSetup()
        try await doProxyTest(type: ProxyTestType.tunnelingHTTP, authType: .basic)
    }

    func testTunnellingHTTPSBasicAuth() async throws {
        try skipIfEnvironmentNotSetup()
        try await doProxyTest(type: ProxyTestType.tunnelingHTTPS, authType: .basic)
    }

    enum ProxyTestType: CaseIterable {
        case forwarding
        case tunnelingHTTP
        case tunnelingHTTPS
        case tunnelingDoubleTLS
        case legacyHTTP
        case legacyHTTPS
    }

    func skipIfEnvironmentNotSetup() throws {
        guard HTTPProxyHost != nil,
              HTTPProxyPort != nil,
              HTTPSProxyHost != nil,
              HTTPSProxyPort != nil,
              HTTPProxyBasicHost != nil,
              HTTPProxyBasicPort != nil,
              HTTPProxyBasicAuthUsername != nil,
              HTTPProxyBasicAuthPassword != nil,
              HTTPProxyTLSCertPath != nil,
              HTTPProxyTLSKeyPath != nil,
              HTTPProxyTLSRootCAPath != nil
        else {
            try skipTest(message: "Skipping PROXY tests because environment is not configured properly.")
            return
        }
    }

    func getURIFromTestType(type: ProxyTestType) -> String {
        switch type {
        case .forwarding, .legacyHTTP, .tunnelingHTTP:
            return "www.example.com"
        default:
            return "www.amazon.com"
        }
    }

    func getPortFromTestType(type: ProxyTestType) -> Int {
        switch type {
        case .forwarding, .legacyHTTP, .tunnelingHTTP:
            return 80
        default:
            return 443
        }
    }

    func getProxyHost(type: ProxyTestType, authType: HTTPProxyAuthenticationType) -> String {
        if authType == HTTPProxyAuthenticationType.basic {
            return HTTPProxyBasicHost!
        }
        if type == ProxyTestType.tunnelingDoubleTLS {
            return HTTPSProxyHost!
        }
        return HTTPProxyHost!
    }

    func getProxyPort(type: ProxyTestType, authType: HTTPProxyAuthenticationType) -> String {
        if authType == HTTPProxyAuthenticationType.basic {
            return HTTPProxyBasicPort!
        }
        if type == ProxyTestType.tunnelingDoubleTLS {
            return HTTPSProxyPort!
        }
        return HTTPProxyPort!
    }

    func getConnectionType(type: ProxyTestType) -> HTTPProxyConnectionType {
        if type == ProxyTestType.forwarding {
            return HTTPProxyConnectionType.forward
        }
        if type == ProxyTestType.tunnelingDoubleTLS ||
                   type == ProxyTestType.tunnelingHTTP ||
                   type == ProxyTestType.tunnelingHTTPS {
           return HTTPProxyConnectionType.tunnel
        }
        return HTTPProxyConnectionType.legacy
    }

    func getTLSOptions(type: ProxyTestType) throws -> TLSConnectionOptions? {
        if type == ProxyTestType.tunnelingDoubleTLS {
            let tlsContextOptions = TLSContextOptions()
            tlsContextOptions.setVerifyPeer(false)
            let tlsContext = try TLSContext(options: tlsContextOptions, mode: .client)
            let tlsConnectionOptions = TLSConnectionOptions(context: tlsContext)
            return tlsConnectionOptions
        }
        return nil
    }

    func getProxyOptions(type: ProxyTestType, authType: HTTPProxyAuthenticationType) throws -> HTTPProxyOptions {
        HTTPProxyOptions(
                hostName: getProxyHost(type: type, authType: authType),
                port: UInt32(getProxyPort(type: type, authType: authType))!,
                authType: authType,
                basicAuthUsername: HTTPProxyBasicAuthUsername,
                basicAuthPassword: HTTPProxyBasicAuthPassword,
                tlsOptions: try getTLSOptions(type: type),
                connectionType: getConnectionType(type: type))
    }

    func getSSH(type: ProxyTestType) -> Bool {
         return !(type == ProxyTestType.forwarding ||
                   type == ProxyTestType.legacyHTTP ||
                   type == ProxyTestType.tunnelingHTTP)
    }

    func doProxyTest(type: ProxyTestType, authType: HTTPProxyAuthenticationType) async throws {
        let uri = getURIFromTestType(type: type)
        let port = getPortFromTestType(type: type)
        let proxyOptions = try getProxyOptions(type: type, authType: authType)
        let manager = try await HTTPClientTestFixture.getHttpConnectionManager(
                endpoint: uri,
                ssh: getSSH(type: type),
                port: port,
                alpnList: ["http/1.1"],
                proxyOptions: proxyOptions)
        _ = try await HTTPClientTestFixture.sendHTTPRequest(method: "GET", endpoint: uri, connectionManager: manager)
    }

}
