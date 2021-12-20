#!/bin/bash

swift build -c release -Xlinker -rpath -Xlinker "$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift-5.5/macosx"