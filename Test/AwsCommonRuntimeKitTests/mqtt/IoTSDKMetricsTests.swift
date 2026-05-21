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

  func testCreateMetricsWithUserFeaturesMerged() {
    let customMetrics = IoTDeviceSDKMetrics(libraryName: "CustomSDK/Test")
    customMetrics.metadata["IoTSDKMetricsVersion"] = "1"
    customMetrics.metadata["IoTSDKFeature"] = "L/A,M/B"  // Custom features

    let options = MqttClientOptions(
      hostName: "test.example.com",
      port: 8883,
      sessionBehavior: .clean,
      metrics: customMetrics
    )

    let metrics = IoTSDKMetricsEncoder.createMetrics(from: options)

    // Should use custom library name
    XCTAssertEqual(metrics.libraryName, "CustomSDK/Test")

    // Should have merged features
    let featureList = metrics.metadata["IoTSDKFeature"]
    XCTAssertNotNil(featureList)

    // Should contain CRT features (F/5, G/C, B/A)
    XCTAssertTrue(featureList!.contains("F/5"))  // MQTT5
    XCTAssertTrue(featureList!.contains("B/A"))  // session_behavior = CLEAN

    // Should contain user features
    XCTAssertTrue(featureList!.contains("L/A"))
    XCTAssertTrue(featureList!.contains("M/B"))
  }

  func testCreateMetricsWithVersionMismatch() {
    // User provides features with wrong version - should only use CRT features
    var customMetrics = IoTDeviceSDKMetrics(libraryName: "CustomSDK/Test")
    customMetrics.metadata["IoTSDKMetricsVersion"] = "999"  // Wrong version
    customMetrics.metadata["IoTSDKFeature"] = "L/A,M/B"  // Custom features

    let options = MqttClientOptions(
      hostName: "test.example.com",
      port: 8883,
      sessionBehavior: .clean,
      metrics: customMetrics
    )

    let metrics = IoTSDKMetricsEncoder.createMetrics(from: options)

    // Should NOT contain user features due to version mismatch
    let featureList = metrics.metadata["IoTSDKFeature"]
    XCTAssertNotNil(featureList)

    // Should contain CRT features
    XCTAssertTrue(featureList!.contains("F/5"))  // MQTT5

    // Should NOT contain user features
    XCTAssertFalse(featureList!.contains("L/A"))
    XCTAssertFalse(featureList!.contains("M/B"))
  }

  func testCreateMetricsCRTVersionNotModifiable() {
    // User tries to set CRTVersion - should be overwritten
    var customMetrics = IoTDeviceSDKMetrics(libraryName: "CustomSDK/Test")
    customMetrics.metadata["CRTVersion"] = "user-version"

    let options = MqttClientOptions(
      hostName: "test.example.com",
      port: 8883,
      metrics: customMetrics
    )

    let metrics = IoTSDKMetricsEncoder.createMetrics(from: options)

    // CRTVersion should be the library's version, not user's
    XCTAssertEqual(metrics.metadata["CRTVersion"], CommonRuntimeKit.CRTVersion)
  }

  func testCreateMetricsPreservesOtherUserMetadata() {
    // User provides other metadata that should be preserved
    var customMetrics = IoTDeviceSDKMetrics(libraryName: "CustomSDK/Test")
    customMetrics.metadata["CustomKey1"] = "CustomValue1"
    customMetrics.metadata["CustomKey2"] = "CustomValue2"

    let options = MqttClientOptions(
      hostName: "test.example.com",
      port: 8883,
      metrics: customMetrics
    )

    let metrics = IoTSDKMetricsEncoder.createMetrics(from: options)

    // Custom metadata should be preserved
    XCTAssertEqual(metrics.metadata["CustomKey1"], "CustomValue1")
    XCTAssertEqual(metrics.metadata["CustomKey2"], "CustomValue2")
  }

}
