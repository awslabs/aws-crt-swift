import AwsCHttp
import AwsCAuth

public struct AwsCommonRuntimeKit {
  public static let version = "@AWS_CRT_SWIFT_VERSION@"

  public static func initialize(allocator: Allocator = defaultAllocator) {
    aws_auth_library_init(allocator.rawValue)
  }

  public static func cleanUp() {
    aws_auth_library_clean_up()
  }

  private init() {}
}
