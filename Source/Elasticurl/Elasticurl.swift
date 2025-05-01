//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import ArgumentParser
import AwsCommonRuntimeKit
import Foundation
import _Concurrency

// swiftlint:disable cyclomatic_complexity function_body_length
struct Context: @unchecked Sendable {
  // args
  public var logLevel: LogLevel = .error
  public var verb: String = "GET"
  public var caCert: String?
  public var caPath: String?
  public var certificate: String?
  public var privateKey: String?
  public var connectTimeout: Int = 3000
  public var headers: [String: String] = .init()
  public var includeHeaders: Bool = false
  public var outputFileName: String?
  public var traceFile: String?
  public var insecure: Bool = false
  public var url: URL = .init(fileURLWithPath: "")
  public var data: Data?
  public var alpnList: [String] = []
  public var outputStream = FileHandle.standardOutput
}

@main
struct Elasticurl: AsyncParsableCommand {
  @Option(name: .long, help: "Path to a CA certificate file")
  var cacert: String?

  @Option(name: .long, help: "Path to a directory containing CA files")
  var capath: String?

  @Option(name: .long, help: "Path to a PEM encoded certificate to use with mTLS")
  var cert: String?

  @Option(name: .long, help: "Path to a PEM encoded private key that matches cert")
  var key: String?

  @Option(name: .long, help: "Time in milliseconds to wait for a connection")
  var connectTimeout: Int = 3000

  // Options with both short and long forms
  @Option(
    name: [.customShort("H"), .long],
    help: "Line to send as a header in format [header-key]: [header-value]")
  var header: [String] = []

  @Option(name: [.short, .long], help: "Data to POST or PUT")
  var data: String?

  @Option(name: .long, help: "File to read from file and POST or PUT")
  var dataFile: String?

  @Option(name: [.customShort("M"), .long], help: "HTTP Method verb to use for the request")
  var method: String?

  @Flag(name: [.customShort("G"), .long], help: "Uses GET for the verb")
  var get: Bool = false

  @Flag(name: [.customShort("P"), .long], help: "Uses POST for the verb")
  var post: Bool = false

  @Flag(name: [.customShort("I"), .long], help: "Uses HEAD for the verb")
  var head: Bool = false

  @Flag(name: [.short, .long], help: "Includes headers in output")
  var include: Bool = false

  @Flag(name: [.customShort("k"), .long], help: "Turns off SSL/TLS validation")
  var insecure: Bool = false

  @Option(name: .long, help: "Path to a shared library with an exported signing function to use")
  var signingLib: String?

  @Option(name: .long, help: "Name of the signing function to use within the signing library")
  var signingFunc: String?

  @Option(
    name: .long,
    help: "Key=value pair to pass to the signing function; may be used multiple times")
  var signingContext: [String] = []

  @Option(name: [.short, .long], help: "Dumps content-body to FILE instead of stdout")
  var output: String?

  @Option(name: [.short, .long], help: "Dumps logs to FILE instead of stderr")
  var trace: String?

  @Option(
    name: [.short, .long],
    help: "ERROR|INFO|DEBUG|TRACE: log level to configure. Default is ERROR")
  var verbose: String?

  @Flag(name: .long, help: "HTTP/2 connection required")
  var http2: Bool = false

  @Flag(name: .customLong("http1_1"), help: "HTTP/1.1 connection required")
  var http1_1: Bool = false

  @Argument(help: "URL to make a request to")
  var urlString: String

  func run() async {
    let context = buildContext()
    if let traceFile = context.traceFile {
      print("enable logging with trace file")
      try? Logger.initialize(target: .filePath(traceFile), level: context.logLevel)
    } else {
      print("enable logging with stdout")
      try? Logger.initialize(target: .standardOutput, level: context.logLevel)
    }
    await Elasticurl.run(context)
  }

  func buildContext() -> Context {
    var context = Context()

    // Convert command-line args to Context
    context.caCert = cacert
    context.caPath = capath
    context.certificate = cert
    context.privateKey = key
    context.connectTimeout = connectTimeout
    context.includeHeaders = include
    context.outputFileName = output
    context.traceFile = trace
    context.insecure = insecure

    // Process verbose/log level
    if let verboseLevel = verbose {
      context.logLevel = LogLevel.fromString(string: verboseLevel)
    }

    // Process headers
    for headerString in header {
      let components = headerString.components(separatedBy: ":")
      if components.count >= 2 {
        let key = components[0].trimmingCharacters(in: .whitespaces)
        let value = components[1...].joined(separator: ":").trimmingCharacters(
          in: .whitespaces)
        context.headers[key] = value
      }
    }

    // Process data
    if let stringData = data {
      context.data = stringData.data(using: .utf8)
    } else if let dataFilePath = dataFile {
      guard let url = URL(string: dataFilePath) else {
        print("Path to data file is incorrect or does not exist")
        Foundation.exit(1)
      }
      do {
        context.data = try Data(contentsOf: url)
      } catch {
        print("Failed to read data file: \(error)")
        Foundation.exit(1)
      }
    }

    // Determine HTTP verb
    if let method = method {
      context.verb = method
    } else if get {
      context.verb = "GET"
    } else if post {
      context.verb = "POST"
    } else if head {
      context.verb = "HEAD"
    }

    // Set ALPN list
    if http2 && !http1_1 {
      context.alpnList = ["h2"]
    } else if http1_1 && !http2 {
      context.alpnList = ["http/1.1"]
    } else {
      context.alpnList = ["h2", "http/1.1"]
    }

    // Set URL
    guard let parsedURL = URL(string: urlString) else {
      print("Invalid URL: \(urlString)")
      Foundation.exit(-1)
    }
    context.url = parsedURL

    if let fileName = context.outputFileName {
      let fileManager = FileManager.default
      let path = FileManager.default.currentDirectoryPath + "/" + fileName
      fileManager.createFile(atPath: path, contents: nil, attributes: nil)
      context.outputStream =
        FileHandle(forWritingAtPath: fileName) ?? FileHandle.standardOutput
    }

    return context
  }

  static func writeData(data: Data, context: Context) {
    context.outputStream.write(data)
  }

  static func run(_ context: Context) async {
    do {
      guard let host = context.url.host else {
        print("no proper host was parsed from the url. quitting.")
        Foundation.exit(EXIT_FAILURE)
      }

      CommonRuntimeKit.initialize()

      let port = UInt32(443)

      let tlsContextOptions = TLSContextOptions.makeDefault()
      tlsContextOptions.setAlpnList(context.alpnList)
      let tlsContext = try TLSContext(options: tlsContextOptions, mode: .client)

      var tlsConnectionOptions = TLSConnectionOptions(context: tlsContext)

      tlsConnectionOptions.serverName = host

      let elg = try EventLoopGroup(threadCount: 1)
      let hostResolver = try HostResolver.makeDefault(
        eventLoopGroup: elg, maxHosts: 8, maxTTL: 30)

      let bootstrap = try ClientBootstrap(
        eventLoopGroup: elg,
        hostResolver: hostResolver)

      let socketOptions = SocketOptions(socketType: .stream)

      var stream: HTTPStream?
      let path = context.url.path == "" ? "/" : context.url.path
      let httpRequest: HTTPRequest = try HTTPRequest(method: context.verb, path: path)
      var headers = [HTTPHeader]()
      headers.append(HTTPHeader(name: "Host", value: host))
      headers.append(HTTPHeader(name: "User-Agent", value: "Elasticurl"))
      headers.append(HTTPHeader(name: "Accept", value: "*/*"))
      headers.append(HTTPHeader(name: "Swift", value: "Version 5.4"))

      if let data = context.data {
        let byteBuffer = ByteBuffer(data: data)
        httpRequest.body = byteBuffer
        headers.append(HTTPHeader(name: "Content-length", value: "\(data.count)"))
      }
      httpRequest.addHeaders(headers: headers)

      let httpClientOptions = HTTPClientConnectionOptions(
        clientBootstrap: bootstrap,
        hostName: context.url.host!,
        initialWindowSize: Int.max,
        port: port,
        proxyOptions: nil,
        socketOptions: socketOptions,
        tlsOptions: tlsConnectionOptions,
        monitoringOptions: nil)

      let connectionManager = try HTTPClientConnectionManager(options: httpClientOptions)
      let connection = try await connectionManager.acquireConnection()
      try await withCheckedThrowingContinuation { continuation in
        let onResponse: HTTPRequestOptions.OnResponse = { _, headers in
          for header in headers {
            print(header.name + " : " + header.value)
          }
        }

        let onBody: HTTPRequestOptions.OnIncomingBody = { bodyChunk in
          writeData(data: bodyChunk, context: context)
        }

        let onComplete: HTTPRequestOptions.OnStreamComplete = { result in
          switch result {
          case .success(let status):
            print("response status:\(status)")
            continuation.resume(returning: ())
          case .failure(let error):
            continuation.resume(throwing: error)
          }
        }

        do {
          let requestOptions = HTTPRequestOptions(
            request: httpRequest,
            onResponse: onResponse,
            onIncomingBody: onBody,
            onStreamComplete: onComplete)
          stream = try connection.makeRequest(requestOptions: requestOptions)
          try stream!.activate()
        } catch {
          continuation.resume(throwing: error)
        }
      }

      Foundation.exit(EXIT_SUCCESS)
    } catch let err {
      print(err)
      Foundation.exit(EXIT_FAILURE)
    }
  }
}
