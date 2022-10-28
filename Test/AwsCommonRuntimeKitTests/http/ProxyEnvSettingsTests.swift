//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class ProxyEnvSettingsTests: CrtXCBaseTestCase {

    func testCreateProxyEnvSettings() throws {
        let proxyEnvSetting = ProxyEnvSettings()
        XCTAssertNotNil(proxyEnvSetting)
    }

    func testCreateProxyEnvSettingsNonDefault() throws {
        let connectionType = HttpProxyConnectionType.tunnel;
        let envVarType = HttpProxyEnvType.enable
        let context = try TlsContext(options: TlsContextOptions(defaultClientWithAllocator: allocator), mode: TlsMode.client)
        let tlsOptions = TlsConnectionOptions(context, allocator: allocator)

        let proxyEnvSetting = ProxyEnvSettings(envVarType: envVarType, proxyConnectionType: connectionType, tlsOptions: tlsOptions)
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
