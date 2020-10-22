#!/usr/bin/swift
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCommonRuntimeKit
import Foundation
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
    public var url: String = ""
    public var data: Data?
    public var alpnList: [String] = []

}

struct Elasticurl {
    private static let version = "0.1.0"
    private static var context = Context()

    static func parseArguments() {

        let optionString = "a:b:c:e:f:H:d:g:j:l:m:M:GPHiko:t:v:VwWh"

        let options = [ElasticurlOptions.caCert.rawValue,
                       ElasticurlOptions.caPath.rawValue,
                       ElasticurlOptions.cert.rawValue,
                       ElasticurlOptions.connectTimeout.rawValue,
                       ElasticurlOptions.data.rawValue,
                       ElasticurlOptions.dataFile.rawValue,
                       ElasticurlOptions.get.rawValue,
                       ElasticurlOptions.head.rawValue,
                       ElasticurlOptions.header.rawValue,
                       ElasticurlOptions.help.rawValue,
                       ElasticurlOptions.http2.rawValue,
                       ElasticurlOptions.http1_1.rawValue,
                       ElasticurlOptions.include.rawValue,
                       ElasticurlOptions.insecure.rawValue,
                       ElasticurlOptions.key.rawValue,
                       ElasticurlOptions.method.rawValue,
                       ElasticurlOptions.output.rawValue,
                       ElasticurlOptions.post.rawValue,
                       ElasticurlOptions.signingContext.rawValue,
                       ElasticurlOptions.signingFunc.rawValue,
                       ElasticurlOptions.signingLib.rawValue,
                       ElasticurlOptions.trace.rawValue,
                       ElasticurlOptions.version.rawValue,
                       ElasticurlOptions.verbose.rawValue,
                       ElasticurlOptions.lastOption.rawValue]

        let argumentsDict = CommandLineParser.parseArguments(argc: CommandLine.argc, arguments: CommandLine.unsafeArgv, optionString: optionString, options: options)

        if let caCert = argumentsDict["a"] as? String {
            context.caCert = caCert
        }

        if let caPath = argumentsDict["b"] as? String {
            context.caPath = caPath
        }

        if let certificate = argumentsDict["c"] as? String {
            context.certificate = certificate
        }

        if let privateKey = argumentsDict["e"] as? String {
            context.privateKey = privateKey
        }

        if let connectTimeout = argumentsDict["f"] as? Int {
            context.connectTimeout = connectTimeout
        }

        if let headers = argumentsDict["H"] as? String {
            context.headers.append(headers)
        }

        if let stringData = argumentsDict["d"] as? String {
            context.data = stringData.data(using: .utf8)
        }

        if let dataFilePath = argumentsDict["g"] as? String {

            guard let url = URL(string: dataFilePath) else {
                print("path to data file is incorrect or does not exist")
                exit(-1)
            }
            do {
                context.data = try Data(contentsOf: url)
            } catch {
                exit(-1)
            }
        }

        if let method = argumentsDict["M"] as? String {

            context.verb = method
        }

        if argumentsDict["G"] != nil {
            context.verb = "GET"
        }

        if argumentsDict["P"] != nil {
            context.verb = "POST"
        }

        if argumentsDict["I"] != nil {
            context.verb = "HEAD"
        }

        if argumentsDict["i"] != nil {
            context.includeHeaders = true
        }

        if argumentsDict["k"] != nil {
            context.insecure = true
        }

        if let fileName = argumentsDict["o"] as? String {
            context.outputFileName = fileName
        }

        if let traceFile = argumentsDict["t"] as? String {
            context.traceFile = traceFile
        }

        if let logLevel = argumentsDict["v"] as? String {
            context.logLevel = LogLevel.fromString(string: logLevel)
        }

        if argumentsDict["V"] != nil {
            print("elasticurl \(version)")
            exit(0)
        }

        if let http1 = argumentsDict["w"] as? String {
            context.alpnList.append(http1)
        }

        if let h2 = argumentsDict["W"] as? String {

            context.alpnList.append(h2)
        }

        if argumentsDict["h"] != nil {
            showHelp()
            exit(0)
        }

        //make sure a url was given before we do anything else
        guard let urlString = CommandLine.arguments.last,
            let _ = URL(string: urlString) else {
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
            
            let clientBootstrapCallbackData = ClientBootstrapCallbackData { sempahore in
                sempahore.signal()
            }
            
            let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                                                hostResolver: hostResolver,
                                                callbackData: clientBootstrapCallbackData,
                                                allocator: allocator)

            let socketOptions = SocketOptions(socketType: .stream)

            let semaphore = DispatchSemaphore(value: 0)

            let httpRequest: HttpRequest = HttpRequest(allocator: allocator)
            httpRequest.method = "GET"
            httpRequest.path = "/"

            let headers = HttpHeaders(allocator: allocator)
            if headers.add(name: "Host", value: context.url),
                headers.add(name: "User-Agent", value: "Elasticurl"),
                headers.add(name: "Accept", value: "*/*") {

                httpRequest.addHeaders(headers: headers)
            }

            let onIncomingHeaders: HttpRequestOptions.OnIncomingHeaders = { stream, headerBlock, headers in
                let allHeaders = headers.getAll()
                for header in allHeaders {
                    print(header.name + " : " + header.value)

                }
            }

            let onBody: HttpRequestOptions.OnIncomingBody = { stream, bodyChunk in
                let dataStr = String(decoding: bodyChunk, as: UTF8.self)
                print(dataStr)
            }

            let onBlockDone: HttpRequestOptions.OnIncomingHeadersBlockDone = { stream, block in

            }

            let onComplete: HttpRequestOptions.OnStreamComplete = { stream, errorCode in
                print(errorCode)
            }


            let httpClientOptions = HttpClientConnectionOptions(clientBootstrap: bootstrap,
                                                                hostName: context.url,
                                                                initialWindowSize: Int.max,
                                                                port: port,
                                                                proxyOptions: nil,
                                                                socketOptions: socketOptions,
                                                                tlsOptions: tlsConnectionOptions)

            
            HttpClientConnectionManager.create(options: httpClientOptions).then { result in
                switch result {
                case .success (let connection):
                    print("Connection succeeded")

                    let requestOptions = HttpRequestOptions(request: httpRequest, onIncomingHeaders: onIncomingHeaders, onIncomingHeadersBlockDone: onBlockDone,
                                                            onIncomingBody: onBody,
                                                            onStreamComplete: onComplete)
                    let stream = connection.newClientStream(requestOptions: requestOptions)
                    stream.activate()
                case .failure (let error):
                    print("connection has shut down with error: \(error.localizedDescription)" )
                    semaphore.signal()
                }
            }
            semaphore.wait()
        } catch {
            showHelp()
            exit(-1)
        }
    }
}
Elasticurl.run()
