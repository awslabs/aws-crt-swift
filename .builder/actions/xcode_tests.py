import Builder
import os
import sys

class XCodeTests(Builder.Action):
    def run(self, env):
        destination = env.shell.getenv("XCODE_DESTINATION")
        Builder.Script(["xcodebuld -scheme AwsCommonRuntimeKit test -destination {}".format(destination)], name='xcode-test')
