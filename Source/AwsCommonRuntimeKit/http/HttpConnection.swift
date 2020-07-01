import AwsCHttp

import Foundation

public struct HttpClientConnectionOptions {
  public typealias OnConnectionSetup =  (HttpClientConnection?, Int32) -> Void
  public typealias OnConnectionShutdown = (HttpClientConnection, Int32) -> Void

  public let clientBootstrap: ClientBootstrap
  public let hostName: String
  public let initialWindowSize: Int
  public let port: UInt16
  public let proxyOptions: HttpClientConnectionProxyOptions?
  public fileprivate(set) var socketOptions: SocketOptions
  public let tlsOptions: TlsConnectionOptions?

  public let onConnectionSetup: OnConnectionSetup
  public let onConnectionShutdown: OnConnectionSetup

    public init(clientBootstrap bootstrap: ClientBootstrap,
                hostName: String,
                initialWindowSize: Int = Int.max,
                port: UInt16,
                proxyOptions: HttpClientConnectionProxyOptions?,
                socketOptions: SocketOptions,
                tlsOptions: TlsConnectionOptions?,
                onConnectionSetup: @escaping OnConnectionSetup,
                onConnectionShutdown: @escaping OnConnectionSetup) {
        self.clientBootstrap = bootstrap
        self.hostName = hostName
        self.initialWindowSize = initialWindowSize
        self.port = port
        self.proxyOptions = proxyOptions
        self.socketOptions = socketOptions
        self.tlsOptions = tlsOptions
        self.onConnectionSetup = onConnectionSetup
        self.onConnectionShutdown = onConnectionShutdown
    }
}

public struct HttpClientConnectionProxyOptions {
  public let authType: AwsHttpProxyAuthenticationType
  public let basicAuthUsername: String
  public let basicAuthPassword: String
  public let hostName: String
  public let port: UInt16
  public let tlsOptions: TlsConnectionOptions?
}

public enum AwsHttpProxyAuthenticationType {
  case none
  case basic
}

extension AwsHttpProxyAuthenticationType {
  var rawValue: aws_http_proxy_authentication_type {
    switch self {
      case .none:  return AWS_HPAT_NONE
      case .basic: return AWS_HPAT_BASIC
    }
  }
}

extension aws_http_proxy_authentication_type {
  var awsHttpProxyAuthenticationType: AwsHttpProxyAuthenticationType! {
    switch self.rawValue {
      case AWS_HPAT_BASIC.rawValue: return AwsHttpProxyAuthenticationType.basic
      case AWS_HPAT_NONE.rawValue:  return AwsHttpProxyAuthenticationType.none
      default:
        assertionFailure("Unknown aws_socket_domain: \(String(describing: self))")
        return nil // <- Makes compiler happy, but we'd have halted right before reaching here
    }
  }
}

fileprivate class HttpClientConnectionCallbackData {
    var managedConnection: HttpClientConnection?
    let allocator: Allocator
    var connectionOptions: HttpClientConnectionOptions

    init(options: HttpClientConnectionOptions, allocator: Allocator) {
        self.connectionOptions = options
        self.allocator = allocator
    }
}

fileprivate class HttpStreamCallbackData {
    let requestOptions: HttpRequestOptions
    var stream: HttpStream?

    fileprivate init(requestOptions: HttpRequestOptions) {
        self.requestOptions = requestOptions
    }
}

public class HttpClientConnection {
    private let allocator : Allocator
    private let rawValue: UnsafeMutablePointer<aws_http_connection>

    fileprivate init(connection: UnsafeMutablePointer<aws_http_connection>, allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
        self.rawValue = connection
    }

    deinit {
        aws_http_connection_release(rawValue)
    }

    public static func createConnection(options: inout HttpClientConnectionOptions, allocator: Allocator = defaultAllocator) {
        let tempHostName = options.hostName.newByteCursor()

        var unmanagedConnectionOptions = aws_http_client_connection_options(
                self_size: 0,
                allocator: allocator.rawValue,
                bootstrap: options.clientBootstrap.rawValue,
                host_name: tempHostName.rawValue,
                port: options.port,
                socket_options: UnsafePointer(&options.socketOptions.rawValue),
                tls_options: nil,
                proxy_options: nil,
                monitoring_options: nil,
                initial_window_size: options.initialWindowSize,
                user_data: nil,
                on_setup: onClientConnectionSetup,
                on_shutdown: onClientConnectionShutdown,
                manual_window_management: false,
                http2_options: nil
        )

        unmanagedConnectionOptions.self_size = MemoryLayout.size(ofValue: unmanagedConnectionOptions)

        if let tlsOptions = options.tlsOptions {
            unmanagedConnectionOptions.tls_options = UnsafePointer(&tlsOptions.rawValue)
        }

        //come back to this,
        //if (connectionOptions.proxyOptions != nil) {
        //    unmanagedConnectionOptions.proxy_options = connectionOptions.proxyOptions.rawValue
        //}

        let callbackData = HttpClientConnectionCallbackData(options: options, allocator: allocator)
        unmanagedConnectionOptions.user_data = Unmanaged.passRetained(callbackData).toOpaque()

        aws_http_client_connect(&unmanagedConnectionOptions)
    }

    public var isOpen: Bool {
       return aws_http_connection_is_open(self.rawValue);
    }

    public func close() {
        return aws_http_connection_close(self.rawValue);
    }

    public func newClientStream(requestOptions: HttpRequestOptions) -> HttpStream {
        var options = aws_http_make_request_options()
        options.self_size = MemoryLayout<aws_http_make_request_options>.size
        options.request = requestOptions.request.rawValue
        options.on_response_body = onIncomingBody
        options.on_response_headers = onIncomingHeaders
        options.on_response_header_block_done = onIncomingHeadersBlockDone
        options.on_complete = onStreamCompleted

        var cbData = HttpStreamCallbackData(requestOptions: requestOptions)
        options.user_data = Unmanaged.passRetained(cbData).toOpaque()

        let stream = HttpStream(httpConnection: self)
        cbData.stream = stream
        stream.httpStream = aws_http_connection_make_request(self.rawValue, &options)

        return stream
    }
}

fileprivate func onIncomingHeaders(_ stream: UnsafeMutablePointer<aws_http_stream>?,  _ headerBlock: aws_http_header_block, _ headerArray: UnsafePointer<aws_http_header>?, _ headersCount: Int,  _ userData: UnsafeMutableRawPointer!) -> Int32 {
    let httpStreamCbData: HttpStreamCallbackData = Unmanaged.fromOpaque(userData).takeUnretainedValue()
    var headers: [HttpHeader] = []

    for header in UnsafeBufferPointer(start: headerArray, count: headersCount) {
        headers.append(header)
    }
    httpStreamCbData.requestOptions.onIncomingHeaders(httpStreamCbData.stream!, headerBlock.headerBlock, headers)
    return 0
}

fileprivate func onIncomingHeadersBlockDone(_ stream: UnsafeMutablePointer<aws_http_stream>?, _ headerBlock: aws_http_header_block, _ userData: UnsafeMutableRawPointer!) -> Int32 {
    let httpStreamCbData: HttpStreamCallbackData = Unmanaged.fromOpaque(userData).takeUnretainedValue()
    httpStreamCbData.requestOptions.onIncomingHeadersBlockDone(httpStreamCbData.stream!, headerBlock.headerBlock)
    return 0
}

fileprivate func onIncomingBody(_ stream: UnsafeMutablePointer<aws_http_stream>?, _ data: UnsafePointer<aws_byte_cursor>?, _ userData: UnsafeMutableRawPointer!) -> Int32 {
    let httpStreamCbData: HttpStreamCallbackData = Unmanaged.fromOpaque(userData).takeUnretainedValue()
    guard let bufPtr = data!.pointee.ptr else {
        return -1
    }
    guard let bufLen = data?.pointee.len else {
        return -1
    }

    let callbackBytes = Data(bytesNoCopy: bufPtr, count: bufLen, deallocator: .none)
    httpStreamCbData.requestOptions.onIncomingBody!(httpStreamCbData.stream!, callbackBytes)

    return 0
}

fileprivate func onStreamCompleted(_ stream: UnsafeMutablePointer<aws_http_stream>?, _ errorCode: Int32, _ userData: UnsafeMutableRawPointer!) {
    let httpStreamCbData: HttpStreamCallbackData = Unmanaged.fromOpaque(userData).takeRetainedValue()
    httpStreamCbData.requestOptions.onStreamComplete!(httpStreamCbData.stream!, errorCode)
}

private func onClientConnectionSetup(_ unmanagedConnection: UnsafeMutablePointer<aws_http_connection>!, _ errorCode: Int32, _ userData: UnsafeMutableRawPointer!) {
        if (unmanagedConnection != nil && errorCode == 0) {
            let callbackData: HttpClientConnectionCallbackData = Unmanaged.fromOpaque(userData).takeUnretainedValue()
            callbackData.managedConnection = HttpClientConnection(connection: unmanagedConnection, allocator: callbackData.allocator)
            callbackData.connectionOptions.onConnectionSetup(callbackData.managedConnection, errorCode)
        } else {
            let callbackData: HttpClientConnectionCallbackData = Unmanaged.fromOpaque(userData).takeRetainedValue()
            callbackData.connectionOptions.onConnectionSetup(nil, errorCode)
        }
    }

private func onClientConnectionShutdown(_ unmanagedConnection: UnsafeMutablePointer<aws_http_connection>?, _ errorCode: Int32, _ userData: UnsafeMutableRawPointer!) {
    let callbackData: HttpClientConnectionCallbackData = Unmanaged.fromOpaque(userData).takeRetainedValue()

    callbackData.connectionOptions.onConnectionShutdown(callbackData.managedConnection, errorCode)
}

public enum HttpHeaderBlock {
  case main
  case informational
  case trailing
}

extension HttpHeaderBlock {
  var rawValue: aws_http_header_block {
    switch self {
      case .main: return AWS_HTTP_HEADER_BLOCK_MAIN
      case .informational: return AWS_HTTP_HEADER_BLOCK_INFORMATIONAL
      case .trailing: return AWS_HTTP_HEADER_BLOCK_TRAILING
    }
  }
}

extension aws_http_header_block {
  var headerBlock : HttpHeaderBlock! {
    switch self.rawValue {
      case AWS_HTTP_HEADER_BLOCK_MAIN.rawValue: return HttpHeaderBlock.main
      case AWS_HTTP_HEADER_BLOCK_INFORMATIONAL.rawValue:  return HttpHeaderBlock.informational
      case AWS_HTTP_HEADER_BLOCK_TRAILING.rawValue: return HttpHeaderBlock.trailing
      default:
        assertionFailure("Unknown aws_http_header_block: \(String(describing: self))")
        return nil // <- Makes compiler happy, but we'd have halted right before reaching here
    }
  }
}

public typealias HttpHeader = aws_http_header

public struct HttpRequestOptions {
    public typealias OnIncomingHeaders =  (_ stream: HttpStream,  _ headerBlock: HttpHeaderBlock, _ headers: [HttpHeader]) -> Void
    public typealias OnIncomingHeadersBlockDone = (_ stream: HttpStream, _ headerBlock: HttpHeaderBlock) -> Void
    public typealias OnIncomingBody = (_ stream: HttpStream, _ bodyChunk: Data) -> Void
    public typealias OnStreamComplete = (_ stream: HttpStream, _ errorCode: Int32) -> Void

    fileprivate let request: HttpRequest
    public let onIncomingHeaders: OnIncomingHeaders
    public let onIncomingHeadersBlockDone: OnIncomingHeadersBlockDone
    public let onIncomingBody: OnIncomingBody?
    public let onStreamComplete: OnStreamComplete?

    public init(request: HttpRequest,
                onIncomingHeaders: @escaping OnIncomingHeaders,
                onIncomingHeadersBlockDone: @escaping OnIncomingHeadersBlockDone,
                onIncomingBody: OnIncomingBody? = nil,
                onStreamComplete: OnStreamComplete? = nil) {
        self.request = request
        self.onIncomingHeaders = onIncomingHeaders
        self.onIncomingHeadersBlockDone = onIncomingHeadersBlockDone
        self.onIncomingBody = onIncomingBody
        self.onStreamComplete = onStreamComplete
    }
}

public class HttpStream {
    internal var httpStream: UnsafeMutablePointer<aws_http_stream>?
    private let httpConnection: HttpClientConnection

    fileprivate init(httpConnection: HttpClientConnection) {
        self.httpConnection = httpConnection
    }

    deinit {
        aws_http_stream_release(httpStream)
    }

    public func getResponseStatusCode() -> Int32 {
        var status: Int32 = 0
        aws_http_stream_get_incoming_response_status(httpStream, &status)
        return status
    }

    public func getConnection() -> HttpClientConnection {
        return httpConnection
    }

    public func updateWindow(incrementBy: Int) {
       aws_http_stream_update_window(httpStream, incrementBy)
    }

    public func activate() {
        aws_http_stream_activate(httpStream)
    }
}

//todo Implement HttpRequestOptions struct tht takes the callbacks starting at lines 162, bind IO::InputStream, bind
// HttpRequest class. Set request on request options on line 99. That's it, then we'll be ready to write elasticurl.
