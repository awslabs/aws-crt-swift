//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCHttp
import XCTest

@testable import AwsCommonRuntimeKit

class HTTPTests: XCBaseTestCase {
  let host = "postman-echo.com"
  let getPath = "/get"

  func testGetHTTPSRequest() async throws {
    let connectionManager = try await HTTPClientTestFixture.getHttpConnectionManager(
      endpoint: host, ssh: true, port: 443)
    _ = try await HTTPClientTestFixture.sendHTTPRequest(
      method: "GET", endpoint: host, path: getPath, connectionManager: connectionManager)
    _ = try await HTTPClientTestFixture.sendHTTPRequest(
      method: "GET", endpoint: host, path: "/delete", expectedStatus: 404,
      connectionManager: connectionManager)
  }

  func testGetHTTPSRequestWithUtf8Header() async throws {
    let connectionManager = try await HTTPClientTestFixture.getHttpConnectionManager(
      endpoint: host, ssh: true, port: 443)
    let utf8Header = HTTPHeader(name: "TestHeader", value: "TestValueWithEmoji🤯")
    let headers = try await HTTPClientTestFixture.sendHTTPRequest(
      method: "GET", endpoint: host,
      path: "/response-headers?\(utf8Header.name)=\(utf8Header.value)",
      connectionManager: connectionManager
    ).headers
    XCTAssertTrue(
      headers.contains(where: { $0.name == utf8Header.name && $0.value == utf8Header.value }))
  }

  func testGetHTTPRequest() async throws {
    let connectionManager = try await HTTPClientTestFixture.getHttpConnectionManager(
      endpoint: host, ssh: false, port: 80)
    _ = try await HTTPClientTestFixture.sendHTTPRequest(
      method: "GET", endpoint: host, path: getPath, connectionManager: connectionManager)
  }

  func testPutHTTPRequest() async throws {
    let connectionManager = try await HTTPClientTestFixture.getHttpConnectionManager(
      endpoint: host, ssh: true, port: 443)
    let response = try await HTTPClientTestFixture.sendHTTPRequest(
      method: "PUT",
      endpoint: host,
      path: "/put",
      body: HTTPClientTestFixture.TEST_DOC_LINE,
      connectionManager: connectionManager)

    // Parse json body
    struct Response: Codable {
      let data: String
    }
    let body: Response = try! JSONDecoder().decode(Response.self, from: response.body)
    XCTAssertEqual(body.data, HTTPClientTestFixture.TEST_DOC_LINE)
  }

  func testHTTPChunkTransferEncoding() async throws {
    let connectionManager = try await HTTPClientTestFixture.getHttpConnectionManager(
      endpoint: host, alpnList: ["http/1.1"])
    let semaphore = TestSemaphore(value: 0)
    var httpResponse = HTTPResponse()
    var onCompleteCalled = false
    let httpRequestOptions = try HTTPClientTestFixture.getHTTPRequestOptions(
      method: "PUT",
      endpoint: host,
      path: "/put",
      response: &httpResponse,
      semaphore: semaphore,
      onComplete: { _ in
        onCompleteCalled = true
      },
      useChunkedEncoding: true)
    let connection = try await connectionManager.acquireConnection()
    let streamBase = try connection.makeRequest(requestOptions: httpRequestOptions)
    try streamBase.activate()
    XCTAssertFalse(onCompleteCalled)
    let metrics = connectionManager.fetchMetrics()
    XCTAssertTrue(metrics.leasedConcurrency > 0)

    let data = HTTPClientTestFixture.TEST_DOC_LINE.data(using: .utf8)!
    for chunk in data.chunked(into: 5) {
      try await streamBase.writeChunk(chunk: chunk, endOfStream: false)
      XCTAssertFalse(onCompleteCalled)
    }

    XCTAssertFalse(onCompleteCalled)
    // Sleep for 5 seconds to make sure onComplete is not triggerred
    try await Task.sleep(nanoseconds: 5_000_000_000)
    XCTAssertFalse(onCompleteCalled)
    try await streamBase.writeChunk(chunk: Data(), endOfStream: true)
    await semaphore.wait()
    XCTAssertTrue(onCompleteCalled)
    XCTAssertNil(httpResponse.error)
    XCTAssertEqual(httpResponse.statusCode, 200)

    // Parse json body
    struct Response: Codable {
      let data: String
    }

    let body: Response = try! JSONDecoder().decode(Response.self, from: httpResponse.body)
    XCTAssertEqual(body.data, HTTPClientTestFixture.TEST_DOC_LINE)
  }

  func testHTTPChunkTransferEncodingWithDataInLastChunk() async throws {
    let connectionManager = try await HTTPClientTestFixture.getHttpConnectionManager(
      endpoint: host, alpnList: ["http/1.1"])
    let semaphore = TestSemaphore(value: 0)
    var httpResponse = HTTPResponse()
    var onCompleteCalled = false
    let httpRequestOptions = try HTTPClientTestFixture.getHTTPRequestOptions(
      method: "PUT",
      endpoint: host,
      path: "/put",
      response: &httpResponse,
      semaphore: semaphore,
      onComplete: { _ in
        onCompleteCalled = true
      },
      useChunkedEncoding: true)
    let connection = try await connectionManager.acquireConnection()
    let streamBase = try connection.makeRequest(requestOptions: httpRequestOptions)
    try streamBase.activate()
    XCTAssertFalse(onCompleteCalled)
    let data = HTTPClientTestFixture.TEST_DOC_LINE.data(using: .utf8)!
    for chunk in data.chunked(into: 5) {
      try await streamBase.writeChunk(chunk: chunk, endOfStream: false)
      XCTAssertFalse(onCompleteCalled)
    }

    XCTAssertFalse(onCompleteCalled)
    // Sleep for 5 seconds to make sure onComplete is not triggerred
    try await Task.sleep(nanoseconds: 5_000_000_000)
    XCTAssertFalse(onCompleteCalled)

    let lastChunkData = Data("last chunk data".utf8)
    try await streamBase.writeChunk(chunk: lastChunkData, endOfStream: true)
    await semaphore.wait()
    XCTAssertTrue(onCompleteCalled)
    XCTAssertNil(httpResponse.error)
    XCTAssertEqual(httpResponse.statusCode, 200)

    // Parse json body
    struct Response: Codable {
      let data: String
    }

    let body: Response = try! JSONDecoder().decode(Response.self, from: httpResponse.body)
    XCTAssertEqual(
      body.data,
      HTTPClientTestFixture.TEST_DOC_LINE + String(decoding: lastChunkData, as: UTF8.self))
  }

  func testHTTPStreamIsReleasedIfNotActivated() async throws {
    do {
      let httpRequestOptions = try HTTPClientTestFixture.getHTTPRequestOptions(
        method: "GET", endpoint: host, path: getPath)
      let connectionManager = try await HTTPClientTestFixture.getHttpConnectionManager(
        endpoint: host, ssh: true, port: 443)
      let connection = try await connectionManager.acquireConnection()
      _ = try connection.makeRequest(requestOptions: httpRequestOptions)
    } catch let err {
      print(err)
    }
  }

  func testStreamLivesUntilComplete() async throws {
    let semaphore = TestSemaphore(value: 0)
    do {
      let httpRequestOptions = try HTTPClientTestFixture.getHTTPRequestOptions(
        method: "GET", endpoint: host, path: getPath, semaphore: semaphore)
      let connectionManager = try await HTTPClientTestFixture.getHttpConnectionManager(
        endpoint: host, ssh: true, port: 443)
      let connection = try await connectionManager.acquireConnection()
      let stream = try connection.makeRequest(requestOptions: httpRequestOptions)
      try stream.activate()
    }
    await semaphore.wait()
  }

  func testManagerLivesUntilComplete() async throws {
    var connection: HTTPClientConnection! = nil
    let semaphore = TestSemaphore(value: 0)

    do {
      let connectionManager = try await HTTPClientTestFixture.getHttpConnectionManager(
        endpoint: host, ssh: true, port: 443)
      connection = try await connectionManager.acquireConnection()
    }
    let httpRequestOptions = try HTTPClientTestFixture.getHTTPRequestOptions(
      method: "GET", endpoint: host, path: getPath, semaphore: semaphore)
    let stream = try connection.makeRequest(requestOptions: httpRequestOptions)
    try stream.activate()
    await semaphore.wait()
  }

  func testConnectionLivesUntilComplete() async throws {
    var stream: HTTPStream! = nil

    let semaphore = TestSemaphore(value: 0)

    do {
      let connectionManager = try await HTTPClientTestFixture.getHttpConnectionManager(
        endpoint: host, ssh: true, port: 443)
      let connection = try await connectionManager.acquireConnection()
      let httpRequestOptions = try HTTPClientTestFixture.getHTTPRequestOptions(
        method: "GET", endpoint: host, path: getPath, semaphore: semaphore)
      stream = try connection.makeRequest(requestOptions: httpRequestOptions)
    }
    try stream.activate()
    await semaphore.wait()
  }

  func testConnectionCloseThrow() async throws {
    let connectionManager = try await HTTPClientTestFixture.getHttpConnectionManager(
      endpoint: host, ssh: true, port: 443)
    let connection = try await connectionManager.acquireConnection()
    connection.close()
    let httpRequestOptions = try HTTPClientTestFixture.getHTTPRequestOptions(
      method: "GET", endpoint: host, path: getPath)
    XCTAssertThrowsError(try connection.makeRequest(requestOptions: httpRequestOptions))
  }

  func testConnectionCloseActivateThrow() async throws {
    let connectionManager = try await HTTPClientTestFixture.getHttpConnectionManager(
      endpoint: host, ssh: true, port: 443)
    let connection = try await connectionManager.acquireConnection()
    let httpRequestOptions = try HTTPClientTestFixture.getHTTPRequestOptions(
      method: "GET", endpoint: host, path: getPath)
    let stream = try connection.makeRequest(requestOptions: httpRequestOptions)
    connection.close()
    XCTAssertThrowsError(try stream.activate())
  }

  func testConnectionCloseIsIdempotent() async throws {
    let connectionManager = try await HTTPClientTestFixture.getHttpConnectionManager(
      endpoint: host, ssh: true, port: 443)
    let connection = try await connectionManager.acquireConnection()
    let httpRequestOptions = try HTTPClientTestFixture.getHTTPRequestOptions(
      method: "GET", endpoint: host, path: getPath)
    let stream = try connection.makeRequest(requestOptions: httpRequestOptions)
    connection.close()
    connection.close()
    connection.close()
    XCTAssertThrowsError(try stream.activate())
  }
}
