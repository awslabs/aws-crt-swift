#!/bin/bash
echo "[!]"
curl -L -o /tmp/http_client_test.py https://raw.githubusercontent.com/awslabs/aws-c-http/main/integration-testing/http_client_test.py
python3 /tmp/http_client_test.py .build/x86_64-apple-macosx/release/Elasticurl
