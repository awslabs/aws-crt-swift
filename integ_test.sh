#!/bin/bash

swift test -Xlinker -rpath -Xlinker "$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift-5.5/macosx"

curl -L -o /tmp/http_client_test.py https://raw.githubusercontent.com/awslabs/aws-c-http/main/integration-testing/http_client_test.py
python3 /tmp/http_client_test.py .build/x86_64-apple-macosx/release/Elasticurl


