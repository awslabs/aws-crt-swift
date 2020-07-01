import AwsCCommon

public protocol ByteCursor {
  var rawValue: aws_byte_cursor { get set }
}

extension aws_byte_cursor : ByteCursor {
  public var rawValue: aws_byte_cursor {
    get { return self }
    set(value) {
      self = value
    }
  }
}

extension aws_byte_cursor {
    public func toString() -> String {
         return String(bytesNoCopy: self.ptr, length: self.len, encoding: String.Encoding.utf8, freeWhenDone: false)!
    }
}

extension String {
  public func newByteCursor() -> ByteCursor {
    return StringByteCursor(self)
  }
}

fileprivate struct StringByteCursor : ByteCursor {
  private let string: ContiguousArray<CChar>
  var rawValue: aws_byte_cursor

  fileprivate init(_ string: String) {
    self.string = string.utf8CString
    self.rawValue = aws_byte_cursor_from_array(self.string.withUnsafeBufferPointer { ptr in return ptr.baseAddress }, self.string.count - 1)
  }
}
