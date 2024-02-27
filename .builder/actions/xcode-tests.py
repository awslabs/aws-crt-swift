import Builder
import os
import sys

class XCodeTests(Builder.Action):
    def run(self, env):
        destination = env.shell.getenv("XCODE_DESTINATION")
        commands =[
            'sudo',
            'xcodebuild',
            '-scheme',
            'aws-crt-swift-Package',
            'test',
            '-destination',
            str('\'platform='+destination+'\'')
        ]
        env.shell.exec(commands, check=True)
