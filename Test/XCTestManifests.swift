#if !canImport(ObjectiveC)
import XCTest

extension AWSCredentialsProviderTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__AWSCredentialsProviderTests = [
        ("testCreateAWSCredentialsProviderChain", testCreateAWSCredentialsProviderChain),
        ("testCreateAWSCredentialsProviderEnv", testCreateAWSCredentialsProviderEnv),
        ("testCreateAWSCredentialsProviderProfile", testCreateAWSCredentialsProviderProfile),
        ("testCreateAWSCredentialsProviderStatic", testCreateAWSCredentialsProviderStatic)
    ]
}

extension BootstrapTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__BootstrapTests = [
        ("testCanCreateBootstrap", testCanCreateBootstrap)
    ]
}

extension EventLoopGroupTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__EventLoopGroupTests = [
        ("testCanCreateGroup", testCanCreateGroup),
        ("testCanCreateGroupWithThreads", testCanCreateGroupWithThreads)
    ]
}

extension FutureTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__FutureTests = [
        ("testFuture", testFuture),
        ("testFutureVoid", testFutureVoid)
    ]
}

extension HostResolverTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__HostResolverTests = [
        ("testCanResolveHosts", testCanResolveHosts)
    ]
}

extension HttpHeaderTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__HttpHeaderTests = [
        ("testAddArrayOfHttpHeaders", testAddArrayOfHttpHeaders),
        ("testCreateHttpHeaders", testCreateHttpHeaders),
        ("testDeleteAllHttpHeaders", testDeleteAllHttpHeaders),
        ("testDeleteHttpHeaders", testDeleteHttpHeaders),
        ("testGetAllHttpHeaders", testGetAllHttpHeaders),
        ("testGetHttpHeaders", testGetHttpHeaders)
    ]
}

extension MqttClientTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__MqttClientTests = [
        ("testMqttClientResourceSafety", testMqttClientResourceSafety)
    ]
}

extension SigV4SigningTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__SigV4SigningTests = [
        ("testCreateSigV4Signer", testCreateSigV4Signer),
        ("testSimpleSigningWithCredentials", testSimpleSigningWithCredentials),
        ("testSimpleSigningWithCredentialsProvider", testSimpleSigningWithCredentialsProvider)
    ]
}

extension TlsContextTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__TlsContextTests = [
        ("testCreateTlsContextWithOptions", testCreateTlsContextWithOptions)
    ]
}

extension TracingAllocatorTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__TracingAllocatorTests = [
        ("testTracingAllocatorCorrectlyTracesAllocations", testTracingAllocatorCorrectlyTracesAllocations)
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AWSCredentialsProviderTests.__allTests__AWSCredentialsProviderTests),
        testCase(BootstrapTests.__allTests__BootstrapTests),
        testCase(EventLoopGroupTests.__allTests__EventLoopGroupTests),
        testCase(FutureTests.__allTests__FutureTests),
        testCase(HostResolverTests.__allTests__HostResolverTests),
        testCase(HttpHeaderTests.__allTests__HttpHeaderTests),
        testCase(MqttClientTests.__allTests__MqttClientTests),
        testCase(SigV4SigningTests.__allTests__SigV4SigningTests),
        testCase(TlsContextTests.__allTests__TlsContextTests),
        testCase(TracingAllocatorTests.__allTests__TracingAllocatorTests)
    ]
}
#endif
