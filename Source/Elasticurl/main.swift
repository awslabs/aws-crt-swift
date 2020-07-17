#!/usr/bin/swift
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCommonRuntimeKit
import Foundation
import AwsCHttp
import AwsCCommon
import Darwin

struct Context {
    //args
    public var logLevel: LogLevel = .trace
    public var verb: String = "GET"
    public var caCert: String?
    public var caPath: String?
    public var certificate: String?
    public var privateKey: String?
    public var connectTimeout: Int = 3000
    public var headers: [String] = [String]()
    public var includeHeaders: Bool = false
    public var outputFileName: String?
    public var traceFile: String?
    public var insecure: Bool = false
    public var url: String?
    public var data: Data?
}

struct Elasticurl {

    private static var context = Context()
    
    static func parseArguments() {
            //static arrray of possible `aws_cli_option` options that could be passed in
             let options = [ElasticurlOptions.caCert, ElasticurlOptions.caPath, ElasticurlOptions.cert, ElasticurlOptions.connectTimeout, ElasticurlOptions.data, ElasticurlOptions.dataFile, ElasticurlOptions.get, ElasticurlOptions.head, ElasticurlOptions.header, ElasticurlOptions.help,  ElasticurlOptions.http2,  ElasticurlOptions.http1_1, ElasticurlOptions.include, ElasticurlOptions.insecure, ElasticurlOptions.key, ElasticurlOptions.method, ElasticurlOptions.output, ElasticurlOptions.post, ElasticurlOptions.signingContext, ElasticurlOptions.signingFunc, ElasticurlOptions.signingLib, ElasticurlOptions.trace, ElasticurlOptions.version, ElasticurlOptions.verbose, ElasticurlOptions.lastOption]
             let argumentsIndexCount = CommandLine.arguments.count - 1
             var argumentDict = [String: String]()
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
                    context.caCert = argumentDict[ElasticurlOptionsType.caCert.rawValue]
                case .caPath:
                    context.caPath = argumentDict[ElasticurlOptionsType.caPath.rawValue]
                case .cert:
                    context.certificate = argumentDict[ElasticurlOptionsType.cert.rawValue]
                case .connectTimeout:
                    guard let connectTimeout = argumentDict[ElasticurlOptionsType.connectTimeout.rawValue] else {
                        continue
                    }
                    context.connectTimeout = Int(connectTimeout) ?? 3000
                case .data:
                    let stringData = argumentDict[ElasticurlOptionsType.data.rawValue]
                    context.data = stringData?.data(using: .utf8)
                case .dataFile:
                    
                    guard let pathToFile = argumentDict[ElasticurlOptionsType.dataFile.rawValue],
                        let url = URL(string: pathToFile) else {
                        print("path to data file is incorrect or does not exist")
                        exit(-1)
                    }
                    do {
                    context.data = try Data(contentsOf: url)
                    }
                    catch {
                        exit(-1)
                    }
                case .get:
                    context.verb = "GET"
                case .head:
                    context.verb = "HEAD"
                case .header:
                    guard let header = argumentDict[ElasticurlOptionsType.header.rawValue] else {
                        print("header value was empty")
                        exit(-1)
                    }
                    context.headers.append(header)
                case .help:
                    showHelp()
                    exit(0)
                case .include:
                    context.includeHeaders = true
                case .insecure:
                    context.insecure = true
                case .key:
                    context.privateKey = argumentDict[ElasticurlOptionsType.key.rawValue]
                case .method:
                    context.verb = argumentDict[ElasticurlOptionsType.method.rawValue] ?? "GET"
                case .output:
                    context.outputFileName = argumentDict[ElasticurlOptionsType.output.rawValue]
                case .post:
                    context.verb = "POST"
                case .trace:
                    context.traceFile = argumentDict[ElasticurlOptionsType.trace.rawValue]
                case .verbose:
                    guard let level = argumentDict[ElasticurlOptionsType.verbose.rawValue] else {
                        continue
                    }
                    
                    let levelAsUInt32 = UInt32(level.toInt32())
                    //TODO: make sure this level is one of the log levels or throw error and end program
                    context.logLevel = LogLevel(rawValue: aws_log_level(levelAsUInt32)) ?? LogLevel.trace
                default:
                    showHelp()
                    exit(0)
                }
             }

        context.url = CommandLine.arguments.last
    }
    
    static func showHelp() {
        print("usage: elasticurl [options] url")
        print("url: url to make a request to. The default is a GET request")
        print("Options:")
        print("      --cacert FILE: path to a CA certficate file.")
        print("      --capath PATH: path to a directory containing CA files.")
        print("  -c, --cert FILE: path to a PEM encoded certificate to use with mTLS")
        print("      --key FILE: Path to a PEM encoded private key that matches cert.")
        print("      --connect-timeout INT: time in milliseconds to wait for a connection.")
        print("  -H, --header LINE: line to send as a header in format [header-key]: [header-value]")
        print("  -d, --data STRING: Data to POST or PUT")
        print("      --data-file FILE: File to read from file and POST or PUT")
        print("  -M, --method STRING: Http Method verb to use for the request")
        print("  -G, --get: uses GET for the verb.")
        print("  -P, --post: uses POST for the verb.")
        print("  -I, --head: uses HEAD for the verb.")
        print("  -i, --include: includes headers in output.")
        print("  -k, --insecure: turns off SSL/TLS validation.")
        print("  -o, --output FILE: dumps content-body to FILE instead of stdout.")
        print("  -t, --trace FILE: dumps logs to FILE instead of stderr.")
        print("  -v, --verbose ERROR|INFO|DEBUG|TRACE: log level to configure. Default is none.")
        print("  -h, --help: Display this message and quit.")
    }
    
    static func run() {
        do {
            //make sure a url was given before we do anything else
            guard let url = CommandLine.arguments.last else {
                print("Invalid URL: \(CommandLine.arguments.last!)")
                exit(-1)
            }
            parseArguments()
            let allocator = TracingAllocator(tracingBytesOf: defaultAllocator)
            let logger = Logger(pipe: stdout, level: context.logLevel, allocator: allocator)

            
            AwsCommonRuntimeKit.initialize(allocator: allocator)
            
            let port = UInt16(443)
            
            let tlsContextOptions = TlsContextOptions(defaultClientWithAllocator: allocator)
            try tlsContextOptions.setAlpnList("h2;http/1.1")
            let tlsContext = try TlsContext(options: tlsContextOptions, mode: .client, allocator: allocator)
            
            let tlsConnectionOptions = tlsContext.newConnectionOptions()
       
            try tlsConnectionOptions.setServerName(url)
            
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
            

            var headers = HttpHeaders(allocator: allocator)
            if headers.add(name: "Host", value: url),
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
                                                                hostName: url,
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
            showHelp()
            exit(-1)
        }
    }
}
Elasticurl.run()

