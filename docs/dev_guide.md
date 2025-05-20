# Memory Management / Pointers
For inter-op with C, there are three memory management techniques. These are described below in order of preference. 
### 1. Ampersand
Read the [Peril Of the Ampersand](https://developer.apple.com/forums/thread/674633) guide for this technique. The sharp edge of this technique is that the pointer is only valid for one function call only.
```Swift
/* YOU CAN DO THIS */
var options = aws_credentials_options()
...
/* C function mustn't keep a copy of the pointer to use later */
let creds = aws_credentials_new_with_options(allocator.rawValue, &options)

/* DO NOT DO THIS */
var options = aws_credentials_options()
var optionPointer = &options;
/* option pointer is invalid from here onwards */
...
let creds = aws_credentials_new_with_options(allocator.rawValue, optionPointer)
```
### 2. Closures
If you need pointers that last more than a single line, you can use helper closure functions like [withUnsafePointer](https://developer.apple.com/documentation/swift/withunsafepointer(to:_:)-35wrn) which will give you a pointer valid inside the closure. The native Swift functions will give you a pointer for one variable at a time and if you have N variables, you will end up with N nested closures. To solve this, we have helper functions in [Utilities.swift](https://github.com/awslabs/aws-crt-swift/blob/main/Source/AwsCommonRuntimeKit/crt/Utilities.swift) with the naming scheme `with*` to have different util functions for different use-cases. The idea was to contain the boiler-plate complexity to a single class so that we can have nicer code in the rest of the places.
```Swift
/* DO THIS */
 guard
let provider: UnsafeMutablePointer<aws_credentials_provider> =
  withByteCursorFromStrings(
    thingName,
    roleAlias,
    endpoint,
    /* These cursors will be only valid inside the closure */
    { thingNameCursor, roleAliasCursor, endPointCursor in
      x509Options.thing_name = thingNameCursor
      x509Options.role_alias = roleAliasCursor
      x509Options.endpoint = endPointCursor
      return withOptionalCStructPointer(
        proxyOptions,
        tlsConnectionOptions
      ) { proxyOptionsPointer, tlsConnectionOptionsPointer in

        x509Options.proxy_options = proxyOptionsPointer
        x509Options.tls_connection_options = tlsConnectionOptionsPointer
        /* C Function mustn't use pointer outside of this closure */
        return aws_credentials_provider_new_x509(allocator.rawValue, &x509Options)
      }
    })
else {
shutdownCallbackCore.release()
throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
}

/* DO NOT DO THIS */
let test = Value()
let storedPointer: UnsafePointer<Value>? = nil
withUnsafePointer(to: test) { pointer in 
  storedPointer = pointer
}
/* storedPointer is invalid here */
```
### 3. Manual Memory Management
For the complete control of allocation/deallocation, you can manage the memory yourself. However, prefer automatic management whenever possible.
```Swift
/* DO THIS */
var rawValue: UnsafeMutablePointer<aws_secitem_options> = allocator.allocate(capacity: 1);
/* rawValue is valid until release is called */
allocator.release(rawValue)
```
# Manual Reference Count Management
Swift automatically manages ref-count of all objects and deallocates them when they go out of scope. Normally, you don't need to do anything fancy or think about memory management apart from resource cycles which can lead to deadlocks and objects never getting cleaned up. However, sometimes you need to acquire a reference to a Swift object so that Swift keeps it alive until C is done using it. You can checkout [ShutdownCallback](https://github.com/awslabs/aws-crt-swift/blob/main/Source/AwsCommonRuntimeKit/crt/ShutdownCallbackCore.swift) class to see an example of this pattern. 
```swift

/* DO THIS */
func callCFunctionWithCallback() {
  /* Retain will increment the ref count */
  let userData = Unmanaged.passRetained(SwiftObjectCore()).toOpaque()
  let options = COptionsStruct(callback: callbackFromC, userData: userData);

  c_function_with_callback(options);
  /* swift will now keep the userData alive until it is released in the callback */
}
/* DO NOT DO THIS */
func callCFunctionWithCallback() {
  /* Retain will increment the ref count */
  let userData = SwiftObjectCore()
  c_function_with_callback(COptionsStruct(callback: callbackFromC, userData: &userData));
  /* user_data will be destroyed here and C will have a dangling pointer to it */
}
private func callbackFromC(userData: UnsafeMutableRawPointer!) {
  ...
  /* release will decrement the ref count and allow the user_data to be destroyed */
  Unmanaged<SwiftObjectCore>.fromOpaque(userData).release()
}
```
# Utility functions
Take a look at the [Utilities.swift](https://github.com/awslabs/aws-crt-swift/blob/main/Source/AwsCommonRuntimeKit/crt/Utilities.swift) and [CStruct.swift](https://github.com/awslabs/aws-crt-swift/blob/main/Source/AwsCommonRuntimeKit/crt/CStruct.swift) for the available utility functions. In general, prefer defining utility functions like these to avoid boiler-plate code everywhere in the code. In these classes, you will find a lot of utility functions to convert between Swift<->C Objects which are needed at many places. 

# Error handling
Unfortunately, Swift's error handling is not great. Swift's error handling design is an enum and adding new cases to enums is a breaking change. We don't want people to have giant switch blocks where they have to handle each error independently or break people when new errors are added. For this reason, the design pattern is to just always throw a [CRTError](https://github.com/awslabs/aws-crt-swift/blob/main/Source/AwsCommonRuntimeKit/crt/CommonRuntimeError.swift) struct as the error. You should not add any new cases to CommonRuntimeError enum unless really necessary.
```swift
/* DO THIS */
/* Example 1: */
throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
/* Example 2: */
throw CommonRunTimeError.crtError(CRTError(code: AWS_ERROR_CBOR_UNEXPECTED_TYPE.rawValue))
