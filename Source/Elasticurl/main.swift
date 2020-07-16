#!/usr/bin/swift
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCommonRuntimeKit
import Foundation
import AwsCHttp
import AwsCCommon

struct Context {
    //args
    public var logLevel: LogLevel
    public var verb: String = "GET"
    public var caCert: String
    public var caPath: String
    public var certificate: String
    public var connectTimeout: Int = 3000
    public var headers: [String] = [String]()
    public var includeHeaders: Bool
    public var outputFileName: String
    public var traceFile: String
    public var insecure: Bool
    public var url: String
    public var data: Data
}

struct Elasticurl {

    private static ctx = Context()
    
    static func parseArguments() {
            //static arrray of possible `aws_cli_option` options that could be passed in
             let options = [ElasticurlOptions.caCert, ElasticurlOptions.caPath, ElasticurlOptions.cert, ElasticurlOptions.connectTimeout, ElasticurlOptions.data, ElasticurlOptions.dataFile, ElasticurlOptions.get, ElasticurlOptions.head, ElasticurlOptions.header, ElasticurlOptions.help,  ElasticurlOptions.http2,  ElasticurlOptions.http1_1, ElasticurlOptions.include, ElasticurlOptions.insecure, ElasticurlOptions.key, ElasticurlOptions.method, ElasticurlOptions.output, ElasticurlOptions.post, ElasticurlOptions.signingContext, ElasticurlOptions.signingFunc, ElasticurlOptions.signingLib, ElasticurlOptions.trace, ElasticurlOptions.version, ElasticurlOptions.verbose, ElasticurlOptions.lastOption]
             let argumentsIndexCount = CommandLine.arguments.count - 1
             var argumentDict = [String: Any]()
            //parse arguemnts with underlying CRT function
             for i in stride(from: 1, to: argumentsIndexCount, by: 2) {
                 
                 var optionIndex: Int32 = Int32(i)
                 let newArgument = CommandLineParser.parseArguments(argc: CommandLine.argc, arguments: CommandLine.unsafeArgv, optionString: "a:b:c:e:f:H:d:g:j:l:m:M:GPHiko:t:v:VwWh", options: options, optionIndex: &optionIndex)
                 print(newArgument)
                 argumentDict.merge(newArgument) { (current, _) in current }
             }
            //looped through parsed arguments and set context
             for key in argumentDict.keys {
                let enumKey = ElasticurlOptionsType(rawValue: key)
                switch enumKey {
                case .caCert:
                    ctx.caCert = argumentDict[ElasticurlOptionsType.caCert.rawValue]
                case .caPath:
                    ctx.caPath = argumentDict[ElasticurlOptionsType.caPath.rawValue]
                case .cert:
                    ctx.certificate = argumentDict[ElasticurlOptionsType.cert.rawValue]
                case .connectTimeout:
                    ctx.connectTimeout = argumentDict[ElasticurlOptionsType.connectTimeout.rawValue]
                case .data:
                    let stringData = argumentDict[ElasticurlOptionsType.data.rawValue] as String
                    ctx.data = stringData.data(using: .utf8)
                
                }
             }
    }
    
    static func run() {
        do {
            parseArguments()
            let allocator = TracingAllocator(tracingBytesOf: defaultAllocator)
            let logger = Logger(pipe: stdout, level: LogLevel.trace, allocator: allocator)

            
            AwsCommonRuntimeKit.initialize(allocator: allocator)
            
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
            httpRequest.method = "GET"
            httpRequest.path = "/"
            
            //new header api
            var headers = HttpHeaders(allocator: allocator)
            if headers.add(name: "Host", value: hostName),
                headers.add(name: "User-Agent", value: "Elasticurl"),
                headers.add(name: "Accept", value: "*/*") {
                
                httpRequest.addHeaders(headers: headers)
            }
            
            
            let onIncomingHeaders: HttpRequestOptions.OnIncomingHeaders =
            { stream, headerBlock, headers in
                for header in headers {
                    if let name = header.name.toString(),
                        let value = header.name.toString() {
                        print(name + " : " + value)
                    }
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
                                                                    if(errorCode != 0) {
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
        } catch {
            
        }
    }
}
Elasticurl.run()

