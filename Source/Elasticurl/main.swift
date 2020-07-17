#!/usr/bin/swift
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCommonRuntimeKit
import Foundation
import AwsCHttp
import AwsCCommon
import Darwin

extension aws_byte_cursor {
    public func toString() -> String? {
        return String(bytesNoCopy: self.ptr, length: self.len, encoding: String.Encoding.utf8, freeWhenDone: false)
    }
}

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
    public var url: String = ""
    public var data: Data?
    public var alpnList: [String] = []
    
}

struct Elasticurl {
    private static let version = "0.1.0"
    private static var context = Context()
    
    static func parseArguments() {
        
        let optionString = "a:b:c:e:f:H:d:g:j:l:m:M:GPHiko:t:v:VwWh"
        
        let options = [ElasticurlOptions.caCert, ElasticurlOptions.caPath, ElasticurlOptions.cert, ElasticurlOptions.connectTimeout, ElasticurlOptions.data, ElasticurlOptions.dataFile, ElasticurlOptions.get, ElasticurlOptions.head, ElasticurlOptions.header, ElasticurlOptions.help,  ElasticurlOptions.http2,  ElasticurlOptions.http1_1, ElasticurlOptions.include, ElasticurlOptions.insecure, ElasticurlOptions.key, ElasticurlOptions.method, ElasticurlOptions.output, ElasticurlOptions.post, ElasticurlOptions.signingContext, ElasticurlOptions.signingFunc, ElasticurlOptions.signingLib, ElasticurlOptions.trace, ElasticurlOptions.version, ElasticurlOptions.verbose, ElasticurlOptions.lastOption]
        
        while(true) {
            
            var optionIndex: Int32 = 0
            
            let opt = aws_cli_getopt_long(CommandLine.argc, CommandLine.unsafeArgv, optionString.asCStr(), options, &optionIndex)

            if opt == -1 || opt == 0 {
                break
            }
            
            guard let char = opt.toString() else {
                print("flag given is unknown")
                exit(-1)
            }
            
            switch char {
            case "a":
                context.caCert = String(cString: aws_cli_optarg)
            case "b":
                context.caPath = String(cString: aws_cli_optarg)
            case "c":
                context.certificate = String(cString: aws_cli_optarg)
            case "e":
                context.privateKey = String(cString: aws_cli_optarg)
            case "f":
                context.connectTimeout = Int(String(cString: aws_cli_optarg)) ?? 3000
            case "H":
                context.headers.append(String(cString: aws_cli_optarg))
            case "d":
                let stringData = String(cString: aws_cli_optarg)
                context.data = stringData.data(using: .utf8)
            case "g":
                guard let url = URL(string: String(cString: aws_cli_optarg)) else {
                    print("path to data file is incorrect or does not exist")
                    exit(-1)
                }
                do {
                    context.data = try Data(contentsOf: url)
                }
                catch {
                    exit(-1)
                }
            case "M":
                context.verb = String(cString: aws_cli_optarg)
            case "G":
                context.verb = "GET"
            case "P":
                context.verb = "POST"
            case "I":
                context.verb = "HEAD"
            case "i":
                context.includeHeaders = true
            case "k":
                context.insecure = true
            case "o":
                context.outputFileName = String(cString: aws_cli_optarg)
            case "t":
                context.traceFile = String(cString: aws_cli_optarg)
            case "v":
                let levelAsUInt32 = UInt32(String(cString: aws_cli_optarg).toInt32())
                context.logLevel = LogLevel(rawValue: aws_log_level(levelAsUInt32))
            case "V":
                print("elasticurl \(version)")
            case "w", "W":
                context.alpnList.append(String(cString: aws_cli_optarg))
            case "h":
                showHelp()
                exit(0)
            default:
                showHelp()
                exit(0)
            }
        }
        
        //make sure a url was given before we do anything else
        guard let urlString = CommandLine.arguments.last,
            let url = URL(string: urlString) else {
                print("Invalid URL: \(CommandLine.arguments.last!)")
                exit(-1)
        }
        context.url = urlString
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
    
    static func enableLogging(allocator: Allocator) {
        if let traceFile = context.traceFile {
            print("enable logging with trace file")
            _ = Logger(filePath: traceFile, level: context.logLevel, allocator: allocator)
        } else {
            print("enable logging with stdout")
            _ = Logger(pipe: stdout, level: context.logLevel, allocator: allocator)
        }
    }
    
    static func run() {
        do {
            parseArguments()
            
            let allocator = TracingAllocator(tracingBytesOf: defaultAllocator)
            let logger = Logger(pipe: stdout, level: context.logLevel, allocator: allocator)

            
            AwsCommonRuntimeKit.initialize(allocator: allocator)
            
            let port = UInt16(443)
            
            let tlsContextOptions = TlsContextOptions(defaultClientWithAllocator: allocator)
            try tlsContextOptions.setAlpnList(context.alpnList.joined(separator: ";"))
            let tlsContext = try TlsContext(options: tlsContextOptions, mode: .client, allocator: allocator)
            
            let tlsConnectionOptions = tlsContext.newConnectionOptions()
            
            try tlsConnectionOptions.setServerName(context.url)
            
            let elg = try EventLoopGroup(threadCount: 1, allocator: allocator)
            let hostResolver = try DefaultHostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30, allocator: allocator)
            let bootstrap = try ClientBootstrap(eventLoopGroup: elg, hostResolver: hostResolver, allocator: allocator)
            
            let socketOptions = SocketOptions(socketType: .stream)
            
            let semaphore = DispatchSemaphore(value: 0)
            
            var stream: HttpStream? = nil
            var connection: HttpClientConnection? = nil
            
            let httpRequest: HttpRequest = HttpRequest(allocator: allocator)
            httpRequest.method = "GET"
            httpRequest.path = "/"
            
            
            let headers = HttpHeaders(allocator: allocator)
            if headers.add(name: "Host", value: context.url),
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
                                                                hostName: context.url,
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
                                                                        
                                                                        let requestOptions = HttpRequestOptions(request: httpRequest, onIncomingHeaders: onIncomingHeaders, onIncomingHeadersBlockDone: onBlockDone,
                                                                                                                onIncomingBody: onBody,
                                                                                                                onStreamComplete: onComplete)
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

