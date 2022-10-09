//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class ProxyEnvSettingsTests: CrtXCBaseTestCase {

    func testCreateProxyEnvSettings() throws {
        let proxyEnvSetting = ProxyEnvSettings(allocator: allocator)
        XCTAssertNotNil(proxyEnvSetting)
    }

    //Todo: tls connection option
    func testCreateProxyEnvSettingsNonDefault() throws {
        let connectionType = HttpProxyConnectionType.tunnel;
        let envVarType = HttpProxyEnvType.enable

        let proxyEnvSetting = ProxyEnvSettings(envVarType: envVarType, proxyConnectionType: connectionType, allocator: allocator)
        XCTAssertNotNil(proxyEnvSetting)

        XCTAssertEqual(proxyEnvSetting.proxyConnectionType, connectionType)
        XCTAssertEqual(proxyEnvSetting.envVarType, envVarType)

        XCTAssertEqual(proxyEnvSetting.rawValue.pointee.connection_type, connectionType.rawValue)
        XCTAssertEqual(proxyEnvSetting.rawValue.pointee.env_var_type, envVarType.rawValue)
    }

}
