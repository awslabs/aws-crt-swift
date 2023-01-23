//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class HTTPProxyEnvSettingsTests: XCBaseTestCase {

    func testCreateProxyEnvSettings() throws {
        let proxyEnvSetting = HTTPProxyEnvSettings()
        XCTAssertNotNil(proxyEnvSetting)
    }

    func testCreateProxyEnvSettingsNonDefault() throws {
        let connectionType = HTTPProxyConnectionType.tunnel
        let envVarType = HTTPProxyEnvType.enable
        let context = try TLSContext(options: TLSContextOptions(allocator: allocator), mode: TLSMode.client)
        let tlsOptions = TLSConnectionOptions(context: context, allocator: allocator)

        let proxyEnvSetting = HTTPProxyEnvSettings(envVarType: envVarType, proxyConnectionType: connectionType, tlsOptions: tlsOptions)
        XCTAssertNotNil(proxyEnvSetting)
        XCTAssertEqual(proxyEnvSetting.proxyConnectionType, connectionType)
        XCTAssertEqual(proxyEnvSetting.envVarType, envVarType)
        XCTAssertNotNil(proxyEnvSetting.tlsOptions)

        proxyEnvSetting.withCStruct{ cProxyEnvSetting in
            XCTAssertEqual(cProxyEnvSetting.connection_type, connectionType.rawValue)
            XCTAssertEqual(cProxyEnvSetting.env_var_type, envVarType.rawValue)
            XCTAssertNotNil(cProxyEnvSetting.tls_options)
        }
    }
}
