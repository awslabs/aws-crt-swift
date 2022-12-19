import AwsCEventStreams
import AwsCAuth

public struct CommonRuntimeKit {

    public static func initialize(allocator: Allocator = defaultAllocator) {
        aws_auth_library_init(allocator.rawValue)
        aws_event_stream_library_init(allocator.rawValue)
    }

    public static func cleanUp() {
        aws_auth_library_clean_up()
        aws_event_stream_library_clean_up()
    }

    private init() {}
}
