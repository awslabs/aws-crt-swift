# DO NOT EDIT
# This makefile makes sure all linkable targets are
# up-to-date with anything they link to
default:
	echo "Do not invoke directly"

# Rules to remove targets that are older than anything to which they
# link.  This forces Xcode to relink the targets from scratch.  It
# does not seem to check these dependencies itself.
PostBuild.aws-c-compression.Debug:
PostBuild.aws-c-common.Debug: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-compression.dylib
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-compression.dylib:\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-common.1.0.0.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-compression.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-compression/aws-c-compression.build/Debug/aws-c-compression.build/$(OBJDIR)/arm64/libaws-c-compression.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-compression/aws-c-compression.build/Debug/aws-c-compression.build/$(OBJDIR)/x86_64/libaws-c-compression.dylib


PostBuild.aws-c-compression.Release:
PostBuild.aws-c-common.Release: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-compression.dylib
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-compression.dylib:\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-common.1.0.0.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-compression.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-compression/aws-c-compression.build/Release/aws-c-compression.build/$(OBJDIR)/arm64/libaws-c-compression.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-compression/aws-c-compression.build/Release/aws-c-compression.build/$(OBJDIR)/x86_64/libaws-c-compression.dylib


PostBuild.aws-c-compression.MinSizeRel:
PostBuild.aws-c-common.MinSizeRel: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-compression.dylib
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-compression.dylib:\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-common.1.0.0.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-compression.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-compression/aws-c-compression.build/MinSizeRel/aws-c-compression.build/$(OBJDIR)/arm64/libaws-c-compression.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-compression/aws-c-compression.build/MinSizeRel/aws-c-compression.build/$(OBJDIR)/x86_64/libaws-c-compression.dylib


PostBuild.aws-c-compression.RelWithDebInfo:
PostBuild.aws-c-common.RelWithDebInfo: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-compression.dylib
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-compression.dylib:\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-common.1.0.0.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-compression.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-compression/aws-c-compression.build/RelWithDebInfo/aws-c-compression.build/$(OBJDIR)/arm64/libaws-c-compression.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-compression/aws-c-compression.build/RelWithDebInfo/aws-c-compression.build/$(OBJDIR)/x86_64/libaws-c-compression.dylib




# For each target create a dummy ruleso the target does not have to exist
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-common.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-common.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-common.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-common.1.0.0.dylib:
