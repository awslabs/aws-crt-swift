# DO NOT EDIT
# This makefile makes sure all linkable targets are
# up-to-date with anything they link to
default:
	echo "Do not invoke directly"

# Rules to remove targets that are older than anything to which they
# link.  This forces Xcode to relink the targets from scratch.  It
# does not seem to check these dependencies itself.
PostBuild.aws-c-http.Debug:
PostBuild.aws-c-io.Debug: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-http.dylib
PostBuild.aws-c-compression.Debug: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-http.dylib
PostBuild.aws-c-common.Debug: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-http.dylib
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-http.dylib:\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-io.1.0.0.dylib\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-compression.1.0.0.dylib\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-common.1.0.0.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-http.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-http/aws-c-http.build/Debug/aws-c-http.build/$(OBJDIR)/arm64/libaws-c-http.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-http/aws-c-http.build/Debug/aws-c-http.build/$(OBJDIR)/x86_64/libaws-c-http.dylib


PostBuild.aws-c-http.Release:
PostBuild.aws-c-io.Release: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-http.dylib
PostBuild.aws-c-compression.Release: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-http.dylib
PostBuild.aws-c-common.Release: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-http.dylib
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-http.dylib:\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-io.1.0.0.dylib\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-compression.1.0.0.dylib\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-common.1.0.0.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-http.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-http/aws-c-http.build/Release/aws-c-http.build/$(OBJDIR)/arm64/libaws-c-http.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-http/aws-c-http.build/Release/aws-c-http.build/$(OBJDIR)/x86_64/libaws-c-http.dylib


PostBuild.aws-c-http.MinSizeRel:
PostBuild.aws-c-io.MinSizeRel: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-http.dylib
PostBuild.aws-c-compression.MinSizeRel: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-http.dylib
PostBuild.aws-c-common.MinSizeRel: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-http.dylib
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-http.dylib:\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-io.1.0.0.dylib\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-compression.1.0.0.dylib\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-common.1.0.0.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-http.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-http/aws-c-http.build/MinSizeRel/aws-c-http.build/$(OBJDIR)/arm64/libaws-c-http.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-http/aws-c-http.build/MinSizeRel/aws-c-http.build/$(OBJDIR)/x86_64/libaws-c-http.dylib


PostBuild.aws-c-http.RelWithDebInfo:
PostBuild.aws-c-io.RelWithDebInfo: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-http.dylib
PostBuild.aws-c-compression.RelWithDebInfo: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-http.dylib
PostBuild.aws-c-common.RelWithDebInfo: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-http.dylib
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-http.dylib:\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-io.1.0.0.dylib\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-compression.1.0.0.dylib\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-common.1.0.0.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-http.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-http/aws-c-http.build/RelWithDebInfo/aws-c-http.build/$(OBJDIR)/arm64/libaws-c-http.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-http/aws-c-http.build/RelWithDebInfo/aws-c-http.build/$(OBJDIR)/x86_64/libaws-c-http.dylib




# For each target create a dummy ruleso the target does not have to exist
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-common.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-compression.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-io.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-common.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-compression.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-io.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-common.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-compression.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-io.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-common.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-compression.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-io.1.0.0.dylib:
