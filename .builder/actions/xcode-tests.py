import Builder
import os
import sys

class XCodeTests(Builder.Action):
    def run(self, env):
        destination = env.shell.getenv("XCODE_DESTINATION")
        platform_string = '\'platform='+destination+'\''
        commands =[
            'sudo',
            'xcodebuild',
            '-scheme',
            'aws-crt-swift-Package',
            'test',
            '-destination',
            platform_string
        ]
        print(commands)
        print(platform_string.strip('\"'))
        commands2 =[
            'sudo',
            'xcodebuild',
            '-scheme',
            'aws-crt-swift-Package',
            'test',
            '-destination',
            platform_string.strip('\"')
        ]
        print(commands2)
        env.shell.exec(commands2, check=True)
