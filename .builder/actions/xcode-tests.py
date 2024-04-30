import Builder
import os
import sys

class XCodeTests(Builder.Action):
    def run(self, env):
        destination = env.shell.getenv("XCODE_DESTINATION")
        commands =[
            'xcodebuild',
            '-scheme',
            'aws-crt-swift-Package',
            'AWS_ACCESS_KEY_ID=${{ env.AWS_ACCESS_KEY_ID }}',
            'AWS_SECRET_ACCESS_KEY=${{ env.AWS_SECRET_ACCESS_KEY }}',
            'test',
            '-destination',
            "platform={}".format(destination)
        ]
        env.shell.exec(commands, check=True)
