//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

@testable import AwsCommonRuntimeKit
import Foundation
import XCTest

class CRTAWSProfileCollectionTests: CrtXCBaseTestCase {
    func testGetProfileCollectionFromBufferConfig() {
        let fakeConfig = "[default]\r\nregion=us-west-2".data(using: .utf8)!
        let buffer = ByteBuffer(data: fakeConfig)
        let profileCollection = CRTAWSProfileCollection(fromBuffer: buffer, source: .config)
        XCTAssertNotNil(profileCollection)
    }

    func testGetProfileCollectionFromBufferCreds() {
        let fakeCreds = "[default]\r\naws_access_key_id=AccessKey\r\naws_secret_access_key=Sekrit".data(using: .utf8)!
        let buffer = ByteBuffer(data: fakeCreds)
        let profileCollection = CRTAWSProfileCollection(fromBuffer: buffer, source: .credentials)
        XCTAssertNotNil(profileCollection)
    }

    func testGetProfileCollectionFromMerge() {
        let fakeConfig = "[default]\r\nregion=us-west-2".data(using: .utf8)!
        let configBuffer = ByteBuffer(data: fakeConfig)
        let profileCollectionConfig = CRTAWSProfileCollection(fromBuffer: configBuffer, source: .config)

        let fakeCreds = "[default]\r\naws_access_key_id=AccessKey\r\naws_secret_access_key=Sekrit".data(using: .utf8)!
        let credBuffer = ByteBuffer(data: fakeCreds)
        let profileCollectionCreds = CRTAWSProfileCollection(fromBuffer: credBuffer, source: .credentials)

        let mergedCollection = CRTAWSProfileCollection(configProfileCollection: profileCollectionConfig, credentialProfileCollection: profileCollectionCreds, source: .credentials)
        XCTAssertNotNil(mergedCollection)
    }
}
