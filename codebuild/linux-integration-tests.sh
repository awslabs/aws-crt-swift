#!/bin/bash

set -euxo pipefail

if test -f "/tmp/setup_proxy_test_env.sh"; then
    source /tmp/setup_proxy_test_env.sh
fi

env

swift -v
swift build
swift test | tee /tmp/tests.log
