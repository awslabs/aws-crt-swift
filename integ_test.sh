#!/bin/bash
curl -L -o /tmp/http_client_test.py https://raw.githubusercontent.com/awslabs/aws-c-http/main/integration-testing/http_client_test.py
ARCH=$(uname -a)
ARCH_STRING="arm64"
echo $ARCH
if [[ "$ARCH" == *x86_64* ]]; then
  ARCH_STRING="x86_64"
fi
python3 /tmp/http_client_test.py .build/$ARCH_STRING-apple-macosx/release/Elasticurl
