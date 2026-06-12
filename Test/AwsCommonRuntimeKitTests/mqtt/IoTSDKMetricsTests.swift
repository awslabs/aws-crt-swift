///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import AwsCommonRuntimeKit

class IoTSDKMetricsTests: XCBaseTestCase {

  // MARK: - Feature List Encoding Tests (Using IoTSDKMetricsEncoder)

  func testMinimalOptionsEncoding() {
    // Create options with minimal settings (all defaults)
    let options = MqttClientOptions(
      hostName: "test.example.com",
      port: 8883
    )

    let encoded = IoTSDKMetricsEncoder.getEncodedFeatureList(from: options)

    // Should always include protocol version (F/5 for MQTT5) and socket implementation
    XCTAssertTrue(encoded.contains("F/5"))  // protocol_version = MQTT5
    XCTAssertTrue(encoded.contains("G/"))  // socket_implementation (platform dependent)

    // Default values should NOT be included
    XCTAssertFalse(encoded.contains("A/"))  // retry_jitter_mode default (FULL) omitted
    XCTAssertFalse(encoded.contains("B/"))  // session_behavior default (CLEAN) omitted
    XCTAssertFalse(encoded.contains("C/"))  // offline_queue_behavior default omitted
  }

  func testOptionsWithMultipleNonDefaultFeaturesEncoding() {
    let topicAliasing = TopicAliasingOptions()
    topicAliasing.outboundBehavior = .lru  // Non-default (default is DISABLED)
    topicAliasing.inboundBehavior = .enabled  // Non-default (default is DISABLED)

    let options = MqttClientOptions(
      hostName: "test.example.com",
      port: 8883,
      sessionBehavior: .rejoinAlways,  // Non-default (default is CLEAN)
      offlineQueueBehavior: .failAllOnDisconnect,  // Non-default
      retryJitterMode: .decorrelated,  // Non-default (default is FULL)
      topicAliasingOptions: topicAliasing
    )

    let encoded = IoTSDKMetricsEncoder.getEncodedFeatureList(from: options)

    // Verify each NON-DEFAULT feature is present with new ID/Value format
    XCTAssertTrue(encoded.contains("A/C"))  // retry_jitter_mode = DECORRELATED
    XCTAssertTrue(encoded.contains("B/C"))  // session_behavior = REJOIN_ALWAYS
    XCTAssertTrue(encoded.contains("C/C"))  // offline_queue_behavior = FAIL_ALL_ON_DISCONNECT
    XCTAssertTrue(encoded.contains("D/B"))  // outbound_topic_alias_behavior = LRU
    XCTAssertTrue(encoded.contains("E/A"))  // inbound_topic_alias_behavior = ENABLED
    XCTAssertTrue(encoded.contains("F/5"))  // protocol_version = MQTT5

    // Verify the format is comma-separated
    let features = encoded.split(separator: ",")
    XCTAssertGreaterThanOrEqual(features.count, 6)
  }

  func testCertificateSourceFromTLSContextOptions() throws {
    // makeDefault() -> no certificate source -> TLSContext has nil certificateSource
    // -> I/ is absent from the encoded feature list
    let defaultTLSOptions = TLSContextOptions.makeDefault()
    let defaultTLSCtx = try TLSContext(options: defaultTLSOptions, mode: .client)
    let optionsWithDefaultTLS = MqttClientOptions(
      hostName: "test.example.com",
      port: 8883,
      tlsCtx: defaultTLSCtx
    )
    XCTAssertFalse(
      IoTSDKMetricsEncoder.getEncodedFeatureList(from: optionsWithDefaultTLS).contains("I/"))

    // For each CertificateSource type, set it on TLSContextOptions, create a TLSContext,
    // pass it to MqttClientOptions, and verify the correct I/X appears in the feature list.
    // In production, certificateSource is set automatically by the factory methods:
    //   makeMTLS(certificatePath:) / makeMTLS(certificateData:) -> .certificateFiles
    //   makeMTLS(pkcs12Path:)                                   -> .pkcs12File
    //   PKCS#11, Windows cert store, Java KeyStore are set by higher-level SDK layers.
    let allCases: [(CertificateSource, String)] = [
      (.certificateFiles, "I/A"),
      (.pkcs11, "I/B"),
      (.windowsCertStore, "I/C"),
      (.javaKeystore, "I/D"),
      (.pkcs12File, "I/E"),
    ]

    for (source, expectedFeature) in allCases {
      let tlsOptions = TLSContextOptions.makeDefault()
      tlsOptions.certificateSource = source

      let tlsCtx = try TLSContext(options: tlsOptions, mode: .client)
      let mqttOptions = MqttClientOptions(
        hostName: "test.example.com",
        port: 8883,
        tlsCtx: tlsCtx
      )
      let encoded = IoTSDKMetricsEncoder.getEncodedFeatureList(from: mqttOptions)
      XCTAssertTrue(
        encoded.contains(expectedFeature),
        "Feature list should contain \(expectedFeature) for certificateSource \(source), got: \(encoded)"
      )
    }
  }

  // MARK: - createMetrics Tests

  func testCreateMetricsWithDefaultOptions() {
    let options = MqttClientOptions(
      hostName: "test.example.com",
      port: 8883,
      sessionBehavior: .clean
    )

    let metrics = IoTSDKMetricsEncoder.createMetrics(from: options)

    // Should have default library name
    XCTAssertEqual(metrics.libraryName, "IoTDeviceSDK/Swift")

    // Should have CRTVersion, IoTSDKFeature, and IoTSDKMetricsVersion
    XCTAssertEqual(metrics.metadata["CRTVersion"], CommonRuntimeKit.CRTVersion)

    let featureList = metrics.metadata["IoTSDKFeature"]
    XCTAssertNotNil(featureList)
    XCTAssertTrue(featureList!.contains("F/5"))  // MQTT5

    XCTAssertEqual(metrics.metadata["IoTSDKMetricsVersion"], "1")
  }

}
