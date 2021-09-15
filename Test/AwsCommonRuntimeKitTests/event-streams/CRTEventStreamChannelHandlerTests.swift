//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import Foundation
@testable import AwsCommonRuntimeKit

class CRTEventStreamChannelHandlerTests: CrtXCBaseTestCase {
    
    func testCreateChannelHandler() {
        let options = CRTEventStreamChannelHandlerOptions { message, error in
            XCTAssertNotNil(message)
            XCTAssert(error.errorCode == 0)
        }
        
        _ = CRTEventStreamChannelHandler(options: options)
    }
    
    func testSendMessage() {
        let header = CRTEventStreamHeader(name: "Test", value: "Value", type: .string)
        let headers = CRTEventStreamHeaders(headers: [header])
        let buffer = ByteBuffer(data: "hello".data(using: .utf8)!)
        let testMessage = CRTEventStreamMessage(headers: headers, payload: buffer)
        let options = CRTEventStreamChannelHandlerOptions { message, error in
            XCTAssert(message.rawValue == testMessage.rawValue)
            XCTAssert(error.errorCode == 0)
        }
        
        let handler = CRTEventStreamChannelHandler(options: options)
        handler.sendMessage(message: testMessage) { message, error in
            XCTAssert(message.rawValue == testMessage.rawValue)
            XCTAssert(error.errorCode == 0)
        }
    }
}
