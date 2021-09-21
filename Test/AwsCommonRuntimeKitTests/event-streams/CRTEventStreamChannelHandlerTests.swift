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
        
        let options = TlsContextOptions(defaultClientWithAllocator: allocator)
        let context = try TlsContext(options: options, mode: .client, allocator: allocator)

        let socketOptions = SocketOptions(socketType: .stream)

        let shutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }

        let resolverShutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }

        let elg = EventLoopGroup(allocator: allocator, shutDownOptions: shutDownOptions)
        let resolver = DefaultHostResolver(eventLoopGroup: elg,
                                               maxHosts: 8,
                                               maxTTL: 30,
                                               allocator: allocator,
                                               shutDownOptions: resolverShutDownOptions)

        let clientBootstrapCallbackData = ClientBootstrapCallbackData { sempahore in
            sempahore.signal()
        }

        let clientBootstrap = try ClientBootstrap(eventLoopGroup: elg,
                                                  hostResolver: resolver,
                                                  callbackData: clientBootstrapCallbackData,
                                                  allocator: allocator)

        clientBootstrap.enableBlockingShutdown = true
        let socketOptions = SocketOptions(socketType: .stream)
        let shutDownCallbackOptions = ShutDownCallbackOptions { sempahore in
            semaphore.signal()
        }
        let options = HttpClientConnectionOptions(clientBootstrap: clientBootstrap,
                                                  hostName: "httpbin.org",
                                                  port: 80,
                                                  proxyOptions: nil,
                                                  socketOptions: socketOptions,
                                                  tlsOptions: context.newConnectionOptions(),
                                                  monitoringOptions: nil,
                                                  shutDownOptions: shutDownCallbackOptions)
        let httpConnectionMgr = HttpClientConnectionManager(options: options)
        let connection = httpConnectionMgr.acquireConnection().then { result in
            let handler = CRTEventStreamChannelHandler(options: options, httpConnection: result.get())
            handler.sendMessage(message: testMessage) { message, error in
                XCTAssert(message.rawValue == testMessage.rawValue)
                XCTAssert(error.errorCode == 0)
            }
        }
    }
}
