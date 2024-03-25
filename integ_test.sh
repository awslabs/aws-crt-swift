#!/bin/bash
curl -L -o /tmp/http_client_test.py https://raw.githubusercontent.com/awslabs/aws-c-http/main/integration-testing/http_client_test.py
ARCH=$(uname -a | sed 's/.* \([^ ]*\)$/\1/')
python3 /tmp/http_client_test.py .build/$ARCH-apple-macosx/release/Elasticurl
