//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit
import AwsCHttp

class HTTP2SettingsTests: XCBaseTestCase {

    func testCreateHTTP2Settings() throws {
        let settings = HTTP2Settings(
                headerTableSize: 10,
                enablePush: false,
                maxConcurrentStreams: 20,
                initialWindowSize: 30,
                maxFrameSize: 40,
                maxHeaderListSize: 50)
        settings.withCStruct { cSettingList in
            XCTAssertEqual(cSettingList.count, 6)
            for cSetting in cSettingList {
                switch cSetting.id {
                case AWS_HTTP2_SETTINGS_HEADER_TABLE_SIZE:
                    XCTAssertEqual(cSetting.value, 10)
                case AWS_HTTP2_SETTINGS_ENABLE_PUSH:
                    XCTAssertEqual(cSetting.value, 0)
                case AWS_HTTP2_SETTINGS_MAX_CONCURRENT_STREAMS:
                    XCTAssertEqual(cSetting.value, 20)
                case AWS_HTTP2_SETTINGS_INITIAL_WINDOW_SIZE:
                    XCTAssertEqual(cSetting.value, 30)
                case AWS_HTTP2_SETTINGS_MAX_FRAME_SIZE:
                    XCTAssertEqual(cSetting.value, 40)
                case AWS_HTTP2_SETTINGS_MAX_HEADER_LIST_SIZE:
                    XCTAssertEqual(cSetting.value, 50)
                default:
                    XCTFail("Unexpected case found")
                }
            }
        }
    }
}
