import AwsCAuth
import AwsCEventStream
import AwsCMqtt
import LibNative
import Foundation

/// Initializes the library.
/// `CommonRuntimeKit.initialize` must be called before using any other functionality.
public struct CommonRuntimeKit {

  /// The current version of the AWS Common Runtime Kit.
  public static let CRTVersion = "0.0.0"
  // The underlying aws_*_library_init C calls use unguarded check-then-act flags
  // (e.g. aws-c-io's s_io_library_initialized), assuming a single-threaded, call-once
  // caller. Swift exposes `initialize()` as public API callable from multiple threads,
  // which can race that flag and return before setup (e.g. TLS trust store) completes.
  // This lock serializes calls; see https://github.com/awslabs/aws-crt-swift/issues/352.
  private static let lock = NSLock()

  /// Initializes the library.
  /// Must be called before using any other functionality.
  public static func initialize() {
    lock.lock()
    defer { lock.unlock() }

    aws_auth_library_init(allocator.rawValue)
    aws_event_stream_library_init(allocator.rawValue)
    aws_mqtt_library_init(allocator.rawValue)
    withUnsafePointer(to: s_crt_swift_error_list) { ptr in
      aws_register_error_info(ptr)
    }
  }

  /**
   * This is an optional cleanup function which will block until all the CRT resources have cleaned up.
   * Use this function only if you want to make sure that there are no memory leaks at the end of the application.
   * Warning: It will hang if you are still holding references to any CRT objects such as HostResolver.
   */
  public static nonisolated func cleanUp() {
    withUnsafePointer(to: s_crt_swift_error_list) { ptr in
      aws_unregister_error_info(ptr)
    }
    aws_mqtt_library_clean_up()
    aws_event_stream_library_clean_up()
    aws_auth_library_clean_up()
  }

  private init() {}
}
