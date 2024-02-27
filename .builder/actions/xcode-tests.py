import Builder
import os
import sys

class XCodeTests(Builder.Action):
    def run(self, env):
        destination = env.shell.getenv("XCODE_DESTINATION")
        env.shell.exec("xcodebuld", "-scheme AwsCommonRuntimeKit test -destination \'{}\'".format(destination),
                       check=True)
