//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCommonRuntimeKit
import Foundation
#if os(Linux)
     import Glibc
 #else
     import Darwin
 #endif

//swiftlint:disable cyclomatic_complexity type_body_length
struct Context {
    //args
    public var logLevel: LogLevel = .trace
    public var verb: String = "GET"
    public var caCert: String?
    public var caPath: String?
    public var certificate: String?
    public var privateKey: String?
    public var connectTimeout: Int = 3000
    public var headers: [String: String] = [String: String]()
    public var includeHeaders: Bool = false
    public var outputFileName: String?
    public var traceFile: String?
    public var insecure: Bool = false
    public var url: URL = URL(fileURLWithPath: "")
    public var data: Data?
    public var alpnList: [String] = []
    public var outputStream = FileHandle.standardOutput

}

struct Elasticurl {
    private static let version = "0.1.0"
    private static var context = Context()
    private static let logger = Logger(pipe: stdout, level: context.logLevel)

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

        let argumentsDict = CommandLineParser.parseArguments(argc: CommandLine.argc,
                                                             arguments: CommandLine.unsafeArgv,
                                                             optionString: optionString, options: options)

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
            let keyValues = headers.components(separatedBy: ",")
            for headerKeyValuePair in keyValues {
                let keyValuePair = headerKeyValuePair.components(separatedBy: ":")
                    let key = keyValuePair[0]
                    let value = keyValuePair[1]
                context.headers[key] = value
            }
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

        if argumentsDict["W"] != nil {
            context.alpnList.append("http/1.1")
        }

        if argumentsDict["w"] != nil {
            context.alpnList.append("h2")
        }

        if argumentsDict["w"] == nil && argumentsDict["W"] == nil {
            context.alpnList.append("h2")
            context.alpnList.append("http/1.1")
        }

        if argumentsDict["h"] != nil {
            showHelp()
            exit(0)
        }

        //make sure a url was given before we do anything else
        guard let urlString = CommandLine.arguments.last,
              let url = URL(string: urlString) else {
            print("Invalid URL: \(CommandLine.arguments.last!)")
            exit(-1)
        }
        context.url = url
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

    static func createOutputFile() {
        if let fileName = context.outputFileName {
            let fileManager = FileManager.default
            let path = FileManager.default.currentDirectoryPath + "/" + fileName
            fileManager.createFile(atPath: path, contents: nil, attributes: nil)
            context.outputStream = FileHandle(forWritingAtPath: fileName) ?? FileHandle.standardOutput
        }
    }

    static func writeData(data: Data) {
        context.outputStream.write(data)
    }

    static func runWithLogger() {
        parseArguments()
        createOutputFile()
        var logger: Logger?
        if let traceFile = context.traceFile {
            print("enable logging with trace file")
            logger = Logger(filePath: traceFile, level: context.logLevel, allocator: defaultAllocator)
        } else {
            print("enable logging with stdout")
            logger = Logger(pipe: stdout, level: context.logLevel, allocator: defaultAllocator)
        }

        withExtendedLifetime(logger) {
            run()
        }
    }

    static func run() {
        Task {
        do {

            guard let host = context.url.host else {
                print("no proper host was parsed from the url. quitting.")
                exit(EXIT_FAILURE)
            }

            let allocator = TracingAllocator(tracingBytesOf: defaultAllocator)

            AwsCommonRuntimeKit.initialize(allocator: allocator)

            let port = UInt16(443)

            let tlsContextOptions = TlsContextOptions(defaultClientWithAllocator: allocator)
            try tlsContextOptions.setAlpnList(context.alpnList.joined(separator: ";"))
            let tlsContext = try TlsContext(options: tlsContextOptions, mode: .client, allocator: allocator)

            let tlsConnectionOptions = tlsContext.newConnectionOptions()

            try tlsConnectionOptions.setServerName(host)

            let elg = EventLoopGroup(threadCount: 1, allocator: allocator)
            let hostResolver = DefaultHostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30, allocator: allocator)

            let clientBootstrapCallbackData = ClientBootstrapCallbackData { sempahore in
                sempahore.signal()
            }

            let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                                                hostResolver: hostResolver,
                                                callbackData: clientBootstrapCallbackData,
                                                allocator: allocator)

            let socketOptions = SocketOptions(socketType: .stream)

            let semaphore = DispatchSemaphore(value: 0)

            var stream: HttpStream?

            let httpRequest: HttpRequest = HttpRequest(allocator: allocator)
            httpRequest.method = context.verb
            let path = context.url.path == "" ? "/" : context.url.path

            httpRequest.path = path

            let headers = HttpHeaders(allocator: allocator)
            if headers.add(name: "Host", value: host),
               headers.add(name: "User-Agent", value: "Elasticurl"),
               headers.add(name: "Accept", value: "*/*"),
               headers.add(name: "Swift", value: "Version 5.4") {
                for header in context.headers {
                    _ = headers.add(name: header.key, value: header.value)
                }
            }

            if let data = context.data {
                let byteBuffer = ByteBuffer(data: data)
                let awsStream = AwsInputStream(byteBuffer)
                httpRequest.body = awsStream
                if headers.add(name: "Content-length", value: "\(data.count)") {
                    httpRequest.addHeaders(headers: headers)
                }
            }
            httpRequest.addHeaders(headers: headers)

            let onIncomingHeaders: HttpRequestOptions.OnIncomingHeaders = { stream, headerBlock, headers in
                let allHeaders = headers.getAll()
                for header in allHeaders {
                    print(header.name + " : " + header.value)

                }
            }

            let onBody: HttpRequestOptions.OnIncomingBody = { stream, bodyChunk in
                writeData(data: bodyChunk)
            }

            let onBlockDone: HttpRequestOptions.OnIncomingHeadersBlockDone = { stream, block in

            }

            let onComplete: HttpRequestOptions.OnStreamComplete = { stream, error in
                if case let CRTError.crtError(unwrappedError) = error {
                    print(unwrappedError.errorMessage ?? "no error message")
                }

                semaphore.signal()
            }

            let httpClientOptions = HttpClientConnectionOptions(clientBootstrap: bootstrap,
                                                                hostName: context.url.host!,
                                                                initialWindowSize: Int.max,
                                                                port: port,
                                                                proxyOptions: nil,
                                                                socketOptions: socketOptions,
                                                                tlsOptions: tlsConnectionOptions,
                                                                monitoringOptions: nil)

            let connectionManager = HttpClientConnectionManager(options: httpClientOptions)
            do {
                let connection = try await connectionManager.acquireConnection()
                let requestOptions = HttpRequestOptions(request: httpRequest,
                                                        onIncomingHeaders: onIncomingHeaders,
                                                        onIncomingHeadersBlockDone: onBlockDone,
                                                        onIncomingBody: onBody,
                                                        onStreamComplete: onComplete)
                stream = connection.makeRequest(requestOptions: requestOptions)
                stream!.activate()
            } catch {
                print("connection has shut down with error: \(error.localizedDescription)" )
                semaphore.signal()
            }

            semaphore.wait()
            exit(EXIT_SUCCESS)
        } catch let err {
            showHelp()
            print(err)
            exit(EXIT_FAILURE)
        }
        }
    }
}

Elasticurl.runWithLogger()
