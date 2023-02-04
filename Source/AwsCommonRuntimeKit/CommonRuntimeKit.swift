import AwsCEventStream
import AwsCAuth

/**
 * Used to initialize the library.
 * `CommonRuntimeKit.initialize` must be called before using any other functionality.
 */
public struct CommonRuntimeKit {

    /**
     * Initializes internal stuff used by CommonRuntimeKit.
     * Must be called before using any other functionality.
     */
    public static func initialize(allocator: Allocator = defaultAllocator) {
        aws_auth_library_init(allocator.rawValue)
        aws_event_stream_library_init(allocator.rawValue)
    }

    /**
     * This is an alternative constructor mainly for testing.
     * Use this instead if you want to override defaultAllocator.
     */
    public static func initialize(customDefaultAllocator: Allocator) {
        aws_auth_library_init(customDefaultAllocator.rawValue)
        aws_event_stream_library_init(customDefaultAllocator.rawValue)
        defaultAllocator = customDefaultAllocator.rawValue
    }

    /**
     * This is an optional cleanup function which will block until all the CRT resources have cleaned up.
     * Use this function only if you want to make sure that there are no memory leaks at the end of the application.
     * Warning: It will hang forever if you are still holding references to CRT Objects like HostResolver.
     */
    public static func cleanUp() {
        aws_auth_library_clean_up()
        aws_event_stream_library_clean_up()
    }

    private init() {}
}
