import AwsCEventStream
import AwsCAuth

/**
 * Initializes the library.
 * `CommonRuntimeKit.initialize` must be called before using any other functionality.
 */
public struct CommonRuntimeKit {

    /// Initializes the library.
    /// Must be called before using any other functionality.
    /// - Parameters:
    ///   - customAllocator: (Optional) allocator to override. If not provided default allocator will be used.
    public static func initialize(customAllocator: Allocator? = nil) {
        if let customAllocator = customAllocator {
            allocator = customAllocator.rawValue
        }
        aws_auth_library_init(allocator.rawValue)
        aws_event_stream_library_init(allocator.rawValue)
    }

    /**
     * This is an optional cleanup function which will block until all the CRT resources have cleaned up.
     * Use this function only if you want to make sure that there are no memory leaks at the end of the application.
     * Warning: It will hang if you are still holding references to any CRT objects such as HostResolver.
     */
    public static func cleanUp() {
        aws_auth_library_clean_up()
        aws_event_stream_library_clean_up()
    }

    private init() {}
}
