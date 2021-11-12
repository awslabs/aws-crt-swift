#!/bin/bash
swift build --build-tests --enable-index-store --configuration debug -Xlinker -rpath -Xlinker "$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift-5.5/macosx"
swift test --skip-build --enable-index-store --configuration debug
swift build -c release -Xlinker -rpath -Xlinker "$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift-5.5/macosx"