# DO NOT EDIT
# This makefile makes sure all linkable targets are
# up-to-date with anything they link to
default:
	echo "Do not invoke directly"

# Rules to remove targets that are older than anything to which they
# link.  This forces Xcode to relink the targets from scratch.  It
# does not seem to check these dependencies itself.
PostBuild.aws-c-cal.Debug:
PostBuild.aws-c-common.Debug: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-cal.dylib
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-cal.dylib:\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-common.1.0.0.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-cal.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-cal/aws-c-cal.build/Debug/aws-c-cal.build/$(OBJDIR)/arm64/libaws-c-cal.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-cal/aws-c-cal.build/Debug/aws-c-cal.build/$(OBJDIR)/x86_64/libaws-c-cal.dylib


PostBuild.aws-c-cal.Release:
PostBuild.aws-c-common.Release: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-cal.dylib
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-cal.dylib:\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-common.1.0.0.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-cal.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-cal/aws-c-cal.build/Release/aws-c-cal.build/$(OBJDIR)/arm64/libaws-c-cal.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-cal/aws-c-cal.build/Release/aws-c-cal.build/$(OBJDIR)/x86_64/libaws-c-cal.dylib


PostBuild.aws-c-cal.MinSizeRel:
PostBuild.aws-c-common.MinSizeRel: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-cal.dylib
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-cal.dylib:\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-common.1.0.0.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-cal.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-cal/aws-c-cal.build/MinSizeRel/aws-c-cal.build/$(OBJDIR)/arm64/libaws-c-cal.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-cal/aws-c-cal.build/MinSizeRel/aws-c-cal.build/$(OBJDIR)/x86_64/libaws-c-cal.dylib


PostBuild.aws-c-cal.RelWithDebInfo:
PostBuild.aws-c-common.RelWithDebInfo: /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-cal.dylib
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-cal.dylib:\
	/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-common.1.0.0.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-cal.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-cal/aws-c-cal.build/RelWithDebInfo/aws-c-cal.build/$(OBJDIR)/arm64/libaws-c-cal.dylib
	/bin/rm -f /Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/aws-common-runtime/aws-c-cal/aws-c-cal.build/RelWithDebInfo/aws-c-cal.build/$(OBJDIR)/x86_64/libaws-c-cal.dylib




# For each target create a dummy ruleso the target does not have to exist
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Debug/libaws-c-common.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/MinSizeRel/libaws-c-common.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/RelWithDebInfo/libaws-c-common.1.0.0.dylib:
/Users/nickik/Projects/Amplify/SmithyCodeGenProject/aws-crt-swift/build-xcode-ios/lib/Release/libaws-c-common.1.0.0.dylib:
