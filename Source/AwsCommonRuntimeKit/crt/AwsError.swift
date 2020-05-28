import AwsCCommon

public enum AwsError : Error {
  case fileNotFound(String)
  case memoryAllocationFailure
  case stringConversionError(UnsafePointer<aws_string>?)
}
