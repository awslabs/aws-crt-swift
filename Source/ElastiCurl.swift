//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCommonRuntimeKit
import Foundation
import AwsCHttp

let allocator = TracingAllocator(tracingBytesOf: defaultAllocator)

AwsCommonRuntimeKit.initialize(allocator: allocator)

let logger = Logger(pipe: stdout, level: LogLevel.trace, allocator: allocator)

// Pretend we get this from the CLI for now

let hostName = "www.amazon.com"
let port = UInt16(443)

// BUSINESS!

let tlsContextOptions = TlsContextOptions(defaultClientWithAllocator: allocator)
try tlsContextOptions.setAlpnList("h2;http/1.1")
let tlsContext = try TlsContext(options: tlsContextOptions, mode: .client, allocator: allocator)

let tlsConnectionOptions = tlsContext.newConnectionOptions()
let serverName = "www.amazon.com"
try tlsConnectionOptions.setServerName(serverName)

let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
let hostResolver = try DefaultHostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30, allocator: allocator)
let bootstrap = try ClientBootstrap(eventLoopGroup: elg, hostResolver: hostResolver, allocator: allocator)

var socketOptions = SocketOptions(socketType: .stream)

let semaphore = DispatchSemaphore(value: 0)

var stream: HttpStream? = nil
var connection: HttpClientConnection? = nil
var httpRequest: HttpRequest = HttpRequest(allocator: allocator)
httpRequest.method = "GET".newByteCursor()
httpRequest.path = "/".newByteCursor()

//new header api
var headers = HttpHeaders()
headers.add(name: "Host", value: hostName)
headers.add(name: "User-Agent", value: "Elasticurl")
headers.add(name: "Accept", value: "*/*")

httpRequest.addHeaders(headers: headers)


let onIncomingHeaders: HttpRequestOptions.OnIncomingHeaders =
        { stream, headerBlock, headers in
            for header in headers {
                print(header.name.toString() + " : " + header.value.toString())
            }
        }

let onBody: HttpRequestOptions.OnIncomingBody =
        { stream, bodyChunk in
            let dataStr = String(decoding: bodyChunk, as: UTF8.self)
            print(dataStr)
        }

let onBlockDone: HttpRequestOptions.OnIncomingHeadersBlockDone =
        { stream, block in
        }

let onComplete: HttpRequestOptions.OnStreamComplete =
        { stream, errorCode in
        }

var httpClientOptions = HttpClientConnectionOptions(clientBootstrap: bootstrap,
        hostName: hostName,
        initialWindowSize: Int.max,
        port: port,
        proxyOptions: nil,
        socketOptions: socketOptions,
        tlsOptions: tlsConnectionOptions,
        onConnectionSetup: { (conn, errorCode) in
            if (errorCode != 0) {
                print("Connection Setup failed with code \(errorCode)")
                exit(-1)
            } else {
                print("Connection succeeded")
                connection = conn

                 let requestOptions = HttpRequestOptions(request: httpRequest, onIncomingHeaders: onIncomingHeaders, onIncomingHeadersBlockDone: onBlockDone, onIncomingBody: onBody, onStreamComplete: onComplete)
                 stream = connection!.newClientStream(requestOptions: requestOptions)
                 stream!.activate()
            }
        },
        onConnectionShutdown: { (connection, errorCode) in
             semaphore.signal()
        })

HttpClientConnection.createConnection(options: &httpClientOptions, allocator: allocator)
semaphore.wait()
