# AwsCommonRuntimeKit
The AWS CRT for Swift is currently in developer preview and is intended strictly for feedback purposes only.
Do not use this for production workloads.

## Building

You can either build with Xcode
```sh
swift package generate-xcodeproj
xed .
```
or in the command line

```sh
swift build
```
To run tests:

```sh
swift test
```

To format the code:
```sh
swift format --in-place --recursive .
```

## Testing

Running Localhost tests:
Localhost tests are run using mock servers from aws-c-http. Use the following instructions from root to run the localhost.
Tests that use localhost within swift: HTTPTests, HTTP2ClientConnectionTests

```sh
cd aws-common-runtime/aws-c-http/tests/mockserver
# install dependencies
python -m pip install h11 h2 trio
# for http/1.1 server
HTTP_PORT=8091 HTTPS_PORT=8092 python h11mock_server.py
# for http/2 non tls server
python h2non_tls_server.py
# for http/2 tls server. 
python h2tls_mock_server.py
# enable localhost env variable for tests to detect localhost server.
export AWS_CRT_LOCALHOST=true
```

We use 4 different ports for running mock servers:
- 3280 and 3443 for HTTP/2 (without TLS and with TLS respectively)
- 8091 and 8092 for HTTP/1.1 (without TLS and with TLS respectively)

To use different ports for HTTP/1.1 server, initialize with different values for HTTP_PORT and HTTPS_PORT. 
Also, change the following lines in HTTPTests.swift.
```swift
  var httpPort: Int {
    ProcessInfo.processInfo.environment["AWS_CRT_LOCALHOST"] != nil ? 8091 : 80
  }
  var httpsPort: Int {
    ProcessInfo.processInfo.environment["AWS_CRT_LOCALHOST"] != nil ? 8092 : 443
  }
```

### Contributor's Guide
**Required Reading:**
- [Development Guide](docs/dev_guide.md)
- [Peril of the Ampersand](https://developer.apple.com/forums/thread/674633)
- [Unmanaged](https://www.mikeash.com/pyblog/friday-qa-2017-08-11-swiftunmanaged.html)
- [Automatic Reference Counting](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html)

**Useful Videos:**
- [Safely manage pointers in Swift](https://developer.apple.com/videos/play/wwdc2020/10167/)
- [Unsafe Swift](https://developer.apple.com/videos/play/wwdc2020/10648)
- [Swift and C Interoperability](https://youtu.be/0kim9mxBOA8)
