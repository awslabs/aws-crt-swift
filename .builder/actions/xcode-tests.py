import Builder
import os
import sys

class XCodeTests(Builder.Action):
    def run(self, env):
        destination = env.shell.getenv("XCODE_DESTINATION")
        env.shell.exec("xcodebuild -scheme aws-crt-swift-Package test -destination \'{}\'".format(destination),
                       check=True)
