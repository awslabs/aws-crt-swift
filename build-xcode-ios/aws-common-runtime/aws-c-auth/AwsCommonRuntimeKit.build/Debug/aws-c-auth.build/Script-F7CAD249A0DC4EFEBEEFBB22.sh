#!/bin/sh
make -C /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-auth -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-auth/CMakeScripts/aws-c-auth_postBuildPhase.make$CONFIGURATION OBJDIR=$(basename "$OBJECT_FILE_DIR_normal") all
