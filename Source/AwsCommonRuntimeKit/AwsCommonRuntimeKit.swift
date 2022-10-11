import AwsCHttp
import AwsCAuth

public struct AwsCommonRuntimeKit {
  public static let version = "@AWS_CRT_SWIFT_VERSION@"

  //Todo: which library to init? Auth does init of http
  public static func initialize(allocator: Allocator = defaultAllocator) {
    aws_http_library_init(allocator.rawValue)
    aws_auth_library_init(allocator.rawValue)
  }

  public static func cleanUp() {
    aws_auth_library_clean_up()
    aws_http_library_clean_up()
  }

  private init() {}
}
