//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCHttp
import AwsCIo
import Foundation

// Swift cannot verify the sendability due to a pointer, and thread safety is handled in the C layer.
// So mark it as unchecked Sendable.
public class HTTPClientConnection: @unchecked Sendable {
  let rawValue: UnsafeMutablePointer<aws_http_connection>
  /// This will keep the connection manager alive until connection is alive
  let manager: HTTPClientConnectionManager

  /// Called by HTTPClientConnectionManager
  init(
    manager: HTTPClientConnectionManager,
    connection: UnsafeMutablePointer<aws_http_connection>
  ) {
    self.manager = manager
    self.rawValue = connection
  }

  public var isOpen: Bool {
    return aws_http_connection_is_open(rawValue)
  }

  public var httpVersion: HTTPVersion {
    HTTPVersion(rawValue: aws_http_connection_get_version(rawValue))
  }

  /// Close the http connection
  public func close() {
    aws_http_connection_close(rawValue)
  }

  /// Creates a new http stream from the `HTTPRequestOptions` given.
  /// The stream will send no data until HTTPStream.activate()
  /// is called. Call activate() when you're ready for callbacks and events to fire.
  /// - Parameter requestOptions: An `HTTPRequestOptions` struct containing callbacks on
  /// the different events from the stream
  /// - Returns: An `HTTPStream` containing the `HTTPClientConnection`
  public func makeRequest(requestOptions: HTTPRequestOptions) throws -> HTTPStream {
    let httpStreamCallbackCore = HTTPStreamCallbackCore(requestOptions: requestOptions)
    do {
      return try HTTP1Stream(
        httpConnection: self,
        options: httpStreamCallbackCore.getRetainedHttpMakeRequestOptions(),
        callbackData: httpStreamCallbackCore)
    } catch {
      httpStreamCallbackCore.release()
      throw error
    }
  }

  deinit {
    try! manager.releaseConnection(connection: self)
  }
}
