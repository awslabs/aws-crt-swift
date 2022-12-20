# AwsCommonRuntimeKit
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

### Contributor's Guide
Required Reading:
- [Peril of the Ampersand](https://developer.apple.com/forums/thread/674633)
- [Unmanaged](https://www.mikeash.com/pyblog/friday-qa-2017-08-11-swiftunmanaged.html)
- [Automatic Reference Counting](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html)

Useful Videos:
- [Safely manage pointers in Swift](https://developer.apple.com/videos/play/wwdc2020/10167/)
- [Unsafe Swift](https://developer.apple.com/videos/play/wwdc2020/10648)
- [Swift and C Interoperability](https://youtu.be/0kim9mxBOA8)
