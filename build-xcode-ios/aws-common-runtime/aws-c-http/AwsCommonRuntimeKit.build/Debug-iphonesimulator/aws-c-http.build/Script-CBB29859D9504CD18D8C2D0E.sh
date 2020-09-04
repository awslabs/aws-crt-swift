#!/bin/sh
make -C /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-http -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-http/CMakeScripts/aws-c-http_postBuildPhase.make$CONFIGURATION OBJDIR=$(basename "$OBJECT_FILE_DIR_normal") all
