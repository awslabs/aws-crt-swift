import AwsCHttp
import AwsCAuth
import AwsCMqtt
import AwsCEventStreams

public struct AwsCommonRuntimeKit {
  public static let version = "@AWS_CRT_SWIFT_VERSION@"

  public static func initialize(allocator: Allocator = defaultAllocator) {
    aws_http_library_init(allocator.rawValue)
    aws_mqtt_library_init(allocator.rawValue)
    aws_event_stream_library_init(allocator.rawValue)
    aws_auth_library_init(allocator.rawValue)
  }

  public static func cleanUp() {
    aws_auth_library_clean_up()
    aws_event_stream_library_clean_up()
    aws_mqtt_library_clean_up()
    aws_http_library_clean_up()
  }

  private init() {}
}
