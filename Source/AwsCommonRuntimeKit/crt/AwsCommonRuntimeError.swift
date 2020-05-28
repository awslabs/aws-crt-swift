import AwsCCommon

public struct AwsCommonRuntimeError : Error {
  private let code = aws_last_error()

  internal init() {}
}
