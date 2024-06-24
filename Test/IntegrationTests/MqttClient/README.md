#  Mqtt Client Sample

This sample is an iOS application that launches the Mqtt Client and subscribes to the topic `test/topic`.

## How to run the application
1. Open project `Samples/MqttClient/MqttClient.xcodeproj` with XCode
2. Signing. Signing is required for iOS application. Setup `Project > Signing & Capabilities > Team` to automatically manage signing.
3. Update Dependency. The project depends on aws-crt-swift. Go to `File > Add package dependency > Add Local ... ` and select your local aws-crt-swift. Alternatively, you can also enter Package URL `https://github.com/awslabs/aws-crt-swift` for released versions.
4. Run the application.


## Q&A
### Couldn't load aws-crt-swift because it is already opened from another project or workspace
You have to close aws-crt-swift before you launch the project. Sometimes XCode would cache the library. Shutdown XCode and reopen the project. Close all XCode Project before launch the project.

### Could not find AwsCommonRuntimeKit
1. Make sure the AwsCommonRuntimeKit was added to the target dependency. Select `Project > General > Frameworks, Libraries, and Embedded Content`.
2. If the dependency was set correctly, try

    a. Update the Package Dependencies, and make sure there is no error in the package.
    b. Re-launch the project
