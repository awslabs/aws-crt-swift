#!/bin/bash

set -euxo pipefail

if test -f "/tmp/setup_proxy_test_env.sh"; then
    source /tmp/setup_proxy_test_env.sh
fi

env

swift -v
python3 -c "from urllib.request import urlretrieve; urlretrieve('$BUILDER_HOST/$BUILDER_SOURCE/$BUILDER_VERSION/builder.pyz?run=$CODEBUILD_BUILD_ID', 'builder.pyz')"
python3 builder.pyz build --project $PACKAGE_NAME downstream --cmake-extra=-DUSE_OPENSSL=ON
