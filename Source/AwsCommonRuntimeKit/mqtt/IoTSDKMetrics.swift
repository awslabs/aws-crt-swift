///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import AwsCCommon
import AwsCMqtt
import Foundation

// MARK: - Metadata Entry

/// A key-value pair for IoT SDK metrics metadata.
/// This class is used internally to convert Swift dictionary entries to C structures.
class MetadataEntry: CStruct, @unchecked Sendable {

  /// Metadata key
  let key: String

  /// Metadata value
  let value: String

  init(key: String, value: String) {
    self.key = key
    self.value = value

    withByteCursorFromStrings(self.key, self.value) { cKeyCursor, cValueCursor in
      aws_byte_buf_init_copy_from_cursor(&keyBuffer, allocator, cKeyCursor)
      aws_byte_buf_init_copy_from_cursor(&valueBuffer, allocator, cValueCursor)
    }
  }

  typealias RawType = aws_mqtt_metadata_entry
  func withCStruct<Result>(_ body: (aws_mqtt_metadata_entry) -> Result) -> Result {
    var rawEntry = aws_mqtt_metadata_entry()
    rawEntry.key = aws_byte_cursor_from_buf(&keyBuffer)
    rawEntry.value = aws_byte_cursor_from_buf(&valueBuffer)
    return body(rawEntry)
  }

  // Keep memory of the buffer storage in the class, and release it on destruction
  private var keyBuffer: aws_byte_buf = aws_byte_buf()
  private var valueBuffer: aws_byte_buf = aws_byte_buf()

  deinit {
    aws_byte_buf_clean_up(&keyBuffer)
    aws_byte_buf_clean_up(&valueBuffer)
  }
}

// MARK: - IoT Device SDK Metrics

/// Configuration for the AWS IoT Device SDK Metrics.
/// This structure is used to pass metrics configuration from the SDK layer through the CRT to aws-c-mqtt.
///
/// The metrics will be appended to the MQTT CONNECT packet's username field.
public class IoTDeviceSDKMetrics: CStruct {
  /// The library name identifier for the SDK (e.g., "IoTDeviceSDK/Swift")
  /// This maps to the SDK attribute in the username field.
  public let libraryName: String

  /// Metadata dictionary for key-value pairs.
  public var metadata: [String: String]

  /// Default library name for Swift SDK
  private static let defaultLibraryName = "IoTDeviceSDK/Swift"

  /// Creates a new IoTDeviceSDKMetrics instance with default library name
  public init() {
    self.libraryName = IoTDeviceSDKMetrics.defaultLibraryName
    self.metadata = [:]
  }

  /// Creates a new IoTDeviceSDKMetrics instance with a custom library name
  /// - Parameter libraryName: The library name to use for metrics (nil uses default)
  public init(libraryName: String?) {
    self.libraryName = libraryName ?? IoTDeviceSDKMetrics.defaultLibraryName
    self.metadata = [:]
  }

  /// Creates a new IoTDeviceSDKMetrics instance with library name and metadata
  /// - Parameters:
  ///   - libraryName: The library name to use for metrics
  ///   - metadata: Dictionary of metadata key-value pairs
  public init(libraryName: String, metadata: [String: String]) {
    self.libraryName = libraryName
    self.metadata = metadata
  }

  typealias RawType = aws_mqtt_iot_metrics
  func withCStruct<Result>(_ body: (aws_mqtt_iot_metrics) -> Result) -> Result {
    var raw_metrics = aws_mqtt_iot_metrics()

    // Convert metadata dictionary to array of MetadataEntry
    let metadataEntries = metadata.map { MetadataEntry(key: $0.key, value: $0.value) }

    return libraryName.withByteCursor { libraryNameByteCursor in
      raw_metrics.library_name = libraryNameByteCursor

      return metadataEntries.withAWSArrayList { metadataPointer in
        raw_metrics.metadata_count = metadataEntries.count
        raw_metrics.metadata_entries = UnsafePointer<aws_mqtt_metadata_entry>(metadataPointer)
        return body(raw_metrics)
      }
    }
  }
}

// MARK: - Feature ID Constants (Package-Private)

/// Feature IDs for IoT SDK metrics tracking.
/// These IDs are used to encode feature usage in the metrics string.
/// Feature IDs are assigned sequentially and are never reused to ensure historical data consistency.
enum MetricsFeatureId {
  static let retryJitterMode: Character = "A"
  static let sessionBehavior: Character = "B"
  static let offlineQueueBehavior: Character = "C"
  static let outboundTopicAliasBehavior: Character = "D"
  static let inboundTopicAliasBehavior: Character = "E"
  static let protocolVersion: Character = "F"
  static let socketImplementation: Character = "G"
  static let httpProxyType: Character = "H"
  static let certificateSource: Character = "I"
  static let tlsCipherPreference: Character = "J"
  static let minimumTlsVersion: Character = "K"
}

// MARK: - Feature Value Constants (Package-Private)
// Only for values that don't map to existing SDK enums

/// Protocol version values for metrics
enum MetricsProtocolVersionValue {
  static let mqtt311: Character = "3"
  static let mqtt5: Character = "5"
}

/// Socket implementation values for metrics
enum MetricsSocketImplementationValue {
  static let posix: Character = "A"
  static let winsock: Character = "B"
  static let appleNetworkFramework: Character = "C"
}

/// HTTP proxy type values for metrics
enum MetricsHttpProxyTypeValue {
  static let http: Character = "A"
  static let https: Character = "B"
}

// MARK: - Extension mappings from existing enums to metrics values (Package-Private)
// Note: Default values return nil to be omitted from the encoded feature list (minimizes payload size)
// Values: A=first option, B=second option, C=third option, etc.

extension ExponentialBackoffJitterMode {
  /// Converts to metrics value character.
  /// Returns nil only for `.default` case to omit from encoded list.
  internal var metricsValue: Character? {
    switch self {
    case .none: return "A"
    case .full: return "B"
    case .decorrelated: return "C"
    case .default: return nil
    }
  }
}

extension ClientSessionBehaviorType {
  /// Converts to metrics value character.
  /// Returns nil only for `.default` case to omit from encoded list.
  internal var metricsValue: Character? {
    switch self {
    case .clean: return "A"
    case .rejoinPostSuccess: return "B"
    case .rejoinAlways: return "C"
    case .default: return nil
    }
  }
}

extension ClientOperationQueueBehaviorType {
  /// Converts to metrics value character.
  /// Returns nil only for `.default` case to omit from encoded list.
  internal var metricsValue: Character? {
    switch self {
    case .failNonQos1PublishOnDisconnect: return "A"
    case .failQos0PublishOnDisconnect: return "B"
    case .failAllOnDisconnect: return "C"
    case .default: return nil
    }
  }
}

extension OutboundTopicAliasBehaviorType {
  /// Converts to metrics value character.
  /// Returns nil only for `.defaultBehavior` case to omit from encoded list.
  internal var metricsValue: Character? {
    switch self {
    case .manual: return "A"
    case .lru: return "B"
    case .disabled: return "C"
    case .defaultBehavior: return nil
    }
  }
}

extension InboundTopicAliasBehaviorType {
  /// Converts to metrics value character.
  /// Returns nil only for `.default` case to omit from encoded list.
  internal var metricsValue: Character? {
    switch self {
    case .enabled: return "A"
    case .disabled: return "B"
    case .default: return nil
    }
  }
}

extension CertificateSource {
  /// Converts to metrics value character for IoT SDK metrics feature ID "I".
  internal var metricsValue: Character {
    switch self {
    case .certificateFiles: return "A"
    case .pkcs11: return "B"
    case .windowsCertStore: return "C"
    case .javaKeystore: return "D"
    case .pkcs12File: return "E"
    }
  }
}

extension TLSVersion {
  /// Converts to metrics value character.
  /// Returns nil for systemDefault to omit from encoded list.
  internal var metricsValue: Character? {
    switch self {
    case .SSLv3: return "A"
    case .TLSv1: return "B"
    case .TLSv1_1: return "C"
    case .TLSv1_2: return "D"
    case .TLSv1_3: return "E"
    case .systemDefault: return nil
    }
  }
}

// MARK: - Metrics Version Constant (Package-Private)

/// The current version of the IoT SDK metrics format
let ioTSDKMetricsFeatureVersion: Int = 1

// MARK: - Feature List Encoding Helper (Package-Private)

/// Helper struct for encoding feature lists from MqttClientOptions.
/// This struct provides static methods to extract and encode metrics directly from client options.
///
/// Note: This struct is package-private and not accessible to external libraries.
struct IoTSDKMetricsEncoder {

  /// Creates the final IoTDeviceSDKMetrics from MqttClientOptions.
  /// This function sets the metrics according to the following rules:
  /// - libraryName: set to default SDK Name. If the libraryName field is set from options.metrics, overwrite the default value
  /// - Metadata - CRTVersion: not modifiable by user, automatically set to CRT version
  /// - Metadata - IoTSDKMetricsVersion: If set by options.metrics, validates whether the metrics version
  ///   matches the library's metrics version and processes IoTSDKFeature
  /// - Metadata - IoTSDKFeature: merge the CRT feature and the input feature if the metrics version matches
  ///
  /// - Parameter options: The MqttClientOptions to extract features from
  /// - Returns: The final IoTDeviceSDKMetrics with all metadata set
  static func createMetrics(from options: MqttClientOptions) -> IoTDeviceSDKMetrics {
    // Determine the library name: use user-provided or default
    let libraryName = options.metrics?.libraryName

    let resultMetrics = IoTDeviceSDKMetrics(libraryName: libraryName)

    // CRTVersion: not modifiable by user, automatically set
    resultMetrics.metadata["CRTVersion"] = CommonRuntimeKit.CRTVersion

    // Get CRT feature list from options
    let crtFeatureList = getEncodedFeatureList(from: options)
    var userFeatureString: String = ""

    if let userMetadata = options.metrics?.metadata {

      if let userFeatureVersion = userMetadata["IoTSDKMetricsVersion"],
        Int(userFeatureVersion) == ioTSDKMetricsFeatureVersion,
        let userFeature = userMetadata["IoTSDKFeature"]
      {
        userFeatureString = userFeature
      }

      for (key, value) in userMetadata
      where key != "IoTSDKFeature" && key != "IoTSDKMetricsVersion" && key != "CRTVersion" {
        resultMetrics.metadata[key] = value
      }
    }

    resultMetrics.metadata["IoTSDKFeature"] = mergeFeatureLists(
      crtFeatures: crtFeatureList, userFeatures: userFeatureString)

    // Always add the current metrics version
    resultMetrics.metadata["IoTSDKMetricsVersion"] = String(ioTSDKMetricsFeatureVersion)

    return resultMetrics
  }

  /// Merges CRT features with user-provided features.
  /// User features take precedence for the same feature ID.
  ///
  /// - Parameters:
  ///   - crtFeatures: The CRT-generated feature list string (e.g., "A/A,B/B")
  ///   - userFeatures: The user-provided feature list string (e.g., "L/A,M/B")
  /// - Returns: The merged feature list string
  private static func mergeFeatureLists(crtFeatures: String, userFeatures: String) -> String {

    // Parse CRT features into a dictionary
    var featureDict: [Character: Character] = [:]
    for feature in crtFeatures.split(separator: ",") {
      let parts = feature.split(separator: "/")
      if parts.count == 2, let featureId = parts[0].first, let value = parts[1].first {
        featureDict[featureId] = value
      }
    }

    // Parse user features and merge (user features take precedence)
    for feature in userFeatures.split(separator: ",") {
      let parts = feature.split(separator: "/")
      if parts.count == 2, let featureId = parts[0].first, let value = parts[1].first {
        featureDict[featureId] = value
      }
    }

    // Convert back to string, sorted by feature ID
    let features = featureDict.keys.map { featureId in
      "\(featureId)/\(featureDict[featureId]!)"
    }

    return features.joined(separator: ",")
  }

  /// Generates the encoded feature list string for metrics directly from MqttClientOptions.
  /// The format is ID/Value pairs separated by commas.
  /// Example: "A/B,C/A" means Feature A (retry_jitter_mode) with value B (FULL),
  ///          and Feature C (offline_queue_behavior) with value A (FAIL_NON_QOS1_PUBLISH_ON_DISCONNECT)
  ///
  /// - Parameter options: The MqttClientOptions to extract features from
  /// - Returns: The encoded feature list string
  static func getEncodedFeatureList(from options: MqttClientOptions) -> String {
    var features: [String] = []

    // A: retry_jitter_mode
    if let value = options.retryJitterMode?.metricsValue {
      features.append("\(MetricsFeatureId.retryJitterMode)/\(value)")
    }

    // B: session_behavior
    if let value = options.sessionBehavior?.metricsValue {
      features.append("\(MetricsFeatureId.sessionBehavior)/\(value)")
    }

    // C: offline_queue_behavior
    if let value = options.offlineQueueBehavior?.metricsValue {
      features.append("\(MetricsFeatureId.offlineQueueBehavior)/\(value)")
    }

    // D: outbound_topic_alias_behavior
    if let value = options.topicAliasingOptions?.outboundBehavior?.metricsValue {
      features.append("\(MetricsFeatureId.outboundTopicAliasBehavior)/\(value)")
    }

    // E: inbound_topic_alias_behavior
    if let value = options.topicAliasingOptions?.inboundBehavior?.metricsValue {
      features.append("\(MetricsFeatureId.inboundTopicAliasBehavior)/\(value)")
    }

    // F: protocol_version - MQTT5 is always used for Mqtt5Client
    features.append("\(MetricsFeatureId.protocolVersion)/\(MetricsProtocolVersionValue.mqtt5)")

    // G: socket_implementation - Detect based on platform
    let socketImpl = detectSocketImplementation()
    features.append("\(MetricsFeatureId.socketImplementation)/\(socketImpl)")

    // H: http_proxy_type - Determine based on whether proxy uses TLS
    if let proxyOptions = options.httpProxyOptions {
      // If the proxy has TLS options configured, it's HTTPS; otherwise HTTP
      let proxyType =
        proxyOptions.tlsOptions != nil
        ? MetricsHttpProxyTypeValue.https : MetricsHttpProxyTypeValue.http
      features.append("\(MetricsFeatureId.httpProxyType)/\(proxyType)")
    }

    // I: certificate_source - automatically derived from TLSContext
    if let certSource = options.tlsCtx?.certificateSource {
      features.append("\(MetricsFeatureId.certificateSource)/\(certSource.metricsValue)")
    }

    // J: tls_cipher_preference - CRT Swift current doesn't have cipher preference support, leave it out for now

    // K: minimum_tls_version - Get from TLSContext if available
    if let tlsCtx = options.tlsCtx,
      let minTlsVersion = tlsCtx.minimumTLSVersion,
      let metricsValue = minTlsVersion.metricsValue
    {
      features.append("\(MetricsFeatureId.minimumTlsVersion)/\(metricsValue)")
    }

    return features.joined(separator: ",")
  }

  /// Help function to determine the socket implementation based on platform.
  private static func detectSocketImplementation() -> Character {
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
      return MetricsSocketImplementationValue.appleNetworkFramework
    #elseif os(Windows)
      return MetricsSocketImplementationValue.winsock
    #else
      return MetricsSocketImplementationValue.posix
    #endif
  }
}
