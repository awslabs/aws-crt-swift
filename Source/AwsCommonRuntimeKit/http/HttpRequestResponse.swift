import AwsCHttp
import AwsCIo

public class HttpMessage {
    internal let rawValue: OpaquePointer
    private let owned: Bool

    public var body: AwsInputStream? {
        willSet(value) {
            if let newBody = value {
                aws_http_message_set_body_stream(self.rawValue, &newBody.rawValue)
            } else {
                aws_http_message_set_body_stream(self.rawValue, nil)
            }
        }
    }

    internal init(owningMessage message: OpaquePointer) {
        self.owned = true
        self.rawValue = message
    }

    internal init(borrowingMessage message: OpaquePointer) {
        self.owned = false
        self.rawValue = message
    }

    deinit {
        if let oldStream = aws_http_message_get_body_stream(self.rawValue) {
            aws_input_stream_destroy(oldStream)
        }
        if self.owned {
            aws_http_message_destroy(self.rawValue)
        }
    }
}

// Header handling
public extension HttpMessage {
    var headerCount: Int {
        return aws_http_message_get_header_count(self.rawValue)
    }

    func addHeader(_ header: HttpHeader) throws {
        if (aws_http_message_add_header(self.rawValue, header) != AWS_OP_SUCCESS) {
            throw AwsCommonRuntimeError()
        }
    }

    func eraseHeader(atIndex index: Int) throws {
        if (aws_http_message_erase_header(self.rawValue, index) != AWS_OP_SUCCESS) {
            throw AwsCommonRuntimeError()
        }
    }

    func getHeader(atIndex index: Int) -> HttpHeader? {
        var header = HttpHeader()
        if (aws_http_message_get_header(self.rawValue, &header, index) != AWS_OP_SUCCESS) {
            return nil
        }
        return header
    }
}

public final class HttpRequest : HttpMessage {
    internal init(message: OpaquePointer) {
        super.init(borrowingMessage: message)
    }

    public init(allocator: Allocator = defaultAllocator) {
        super.init(owningMessage: aws_http_message_new_request(allocator.rawValue))
    }

    public var method: ByteCursor! {
        get {
            var result = aws_byte_cursor()
            if (aws_http_message_get_request_method(self.rawValue, &result) != AWS_OP_SUCCESS) {
                return nil
            }
            return result
        }
        set(value) {
            aws_http_message_set_request_method(self.rawValue, value.rawValue)
        }
    }

    public var path: ByteCursor! {
        get {
            var result = aws_byte_cursor()
            if (aws_http_message_get_request_path(self.rawValue, &result) != AWS_OP_SUCCESS) {
                return nil
            }
            return result
        }
        set(value) {
            // TODO: What when this fails?
            aws_http_message_set_request_path(self.rawValue, value.rawValue)
        }
    }
}

public final class HttpResponse : HttpMessage {
    internal init(message: OpaquePointer, allocator: Allocator) {
        super.init(owningMessage: aws_http_message_new_response(allocator.rawValue))
    }

    public var responseCode: Int! {
        get {
            var response: Int32 = 0
            if (aws_http_message_get_response_status(self.rawValue, &response) != AWS_OP_SUCCESS) {
                return nil
            }
            return Int(response)
        }
        set(value) {
            // TODO: What when this fails?
            aws_http_message_set_response_status(self.rawValue, Int32(value))
        }
    }
}