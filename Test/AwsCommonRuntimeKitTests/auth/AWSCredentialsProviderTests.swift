//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.
import XCTest
@testable import AwsCommonRuntimeKit

class AWSCredentialsProviderTests: CrtXCBaseTestCase {
    let accessKey = "AccessKey"
    let secret = "Sekrit"
    let sessionToken = "Token"
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        if !name.contains("testCreateAWSCredentialsProviderProfile") && !name.contains("testCreateDestroyStsWebIdentityInvalidEnv") && !name.contains("testCreateDestroyStsInvalidRole") {
            wait(for: [expectation2], timeout: 3.0)
        }
    }
    
    func setUpShutDownOptions() -> CRTCredentialsProviderShutdownOptions {
        let shutDownOptions = CRTCredentialsProviderShutdownOptions {
            XCTAssert(true)
        }
        return shutDownOptions
    }
    
    func testCreateAWSCredentialsProviderStatic() async throws {

        let shutDownOptions = setUpShutDownOptions()
        let config = MockCredentialsProviderStaticConfigOptions(accessKey: accessKey,
                                                                secret: secret,
                                                                sessionToken: sessionToken,
                                                                shutDownOptions: shutDownOptions)
        let provider = try CRTAWSCredentialsProvider(fromStatic: config, allocator: allocator)
        let result = await provider.getCredentials()

        switch result {
        case .failure(let error):
            XCTAssertNotNil(error)
        case .success(let credentials):
            print(credentials)
        }
    }
    
    func testCreateAWSCredentialsProviderEnv() async throws {

        let shutDownOptions = setUpShutDownOptions()
        let provider = try CRTAWSCredentialsProvider(fromEnv: shutDownOptions, allocator: allocator)
        let result = await provider.getCredentials()
   
        switch result {
        case .failure(let error):
            XCTAssertNotNil(error)
        case .success(let credentials):
            print(credentials)
        }
    }
    
    func testCreateAWSCredentialsProviderProfile() async throws {
        //skip this test if it is running on macosx or on iOS
        try skipIfiOS()
        try skipifmacOS()
        try skipIfLinux()
        //uses default paths to credentials and config
        let shutDownOptions = setUpShutDownOptions()
        let config = MockCredentialsProviderProfileOptions(shutdownOptions: shutDownOptions)
        
        let provider = try CRTAWSCredentialsProvider(fromProfile: config, allocator: allocator)
        
        let result = await provider.getCredentials()

        switch result {
        case .failure(let error):
            XCTAssertNotNil(error)
        case .success(let credentials):
            print(credentials)
        }
    }
    
    func testCreateAWSCredentialsProviderChain() async throws {
        let elgShutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }
        
        let resolverShutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }
        let elg = EventLoopGroup(threadCount: 0, allocator: allocator, shutDownOptions: elgShutDownOptions)
        let hostResolver = DefaultHostResolver(eventLoopGroup: elg,
                                               maxHosts: 8,
                                               maxTTL: 30,
                                               allocator: allocator,
                                               shutDownOptions: resolverShutDownOptions)
        
        let clientBootstrapCallbackData = ClientBootstrapCallbackData { sempahore in
            sempahore.signal()
        }
        let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                                            hostResolver: hostResolver,
                                            callbackData: clientBootstrapCallbackData,
                                            allocator: allocator)
        bootstrap.enableBlockingShutDown()
        let shutDownOptions = setUpShutDownOptions()
        
        let config = MockCredentialsProviderChainDefaultConfig(bootstrap: bootstrap, shutDownOptions: shutDownOptions)
        
        let provider = try CRTAWSCredentialsProvider(fromChainDefault: config)
        
        let result = await provider.getCredentials()
        switch result {
        case .failure(let error):
            XCTAssertNotNil(error)
        case .success(let credentials):
            print(credentials)
        }
    }
    
    func testCreateDestroyStsWebIdentityInvalidEnv() {
        let elgShutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }
        
        let resolverShutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }
        
        let elg = EventLoopGroup(threadCount: 0, allocator: allocator, shutDownOptions: elgShutDownOptions)
        let hostResolver = DefaultHostResolver(eventLoopGroup: elg,
                                               maxHosts: 8,
                                               maxTTL: 30,
                                               allocator: allocator,
                                               shutDownOptions: resolverShutDownOptions)
        
        let clientBootstrapCallbackData = ClientBootstrapCallbackData { sempahore in
            sempahore.signal()
        }
        
        do {
            let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                                                hostResolver: hostResolver,
                                                callbackData: clientBootstrapCallbackData,
                                                allocator: allocator)
            bootstrap.enableBlockingShutDown()
            let options = TlsContextOptions(defaultClientWithAllocator: allocator)
            let context = try TlsContext(options: options, mode: .client, allocator: allocator)
            let config = MockCredentialsProviderWebIdentityConfig(bootstrap: bootstrap, tlsContext: context)
            _ = try CRTAWSCredentialsProvider(fromWebIdentity: config)
        } catch let err {
            let awsErr = err as? AWSCommonRuntimeError
            XCTAssertEqual(awsErr?.code, 0)
        }
    }
    
    func testCreateDestroyStsInvalidRole() {
        let elgShutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }
        
        let resolverShutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }
        
        let elg = EventLoopGroup(threadCount: 0, allocator: allocator, shutDownOptions: elgShutDownOptions)
        let hostResolver = DefaultHostResolver(eventLoopGroup: elg,
                                               maxHosts: 8,
                                               maxTTL: 30,
                                               allocator: allocator,
                                               shutDownOptions: resolverShutDownOptions)
        
        let clientBootstrapCallbackData = ClientBootstrapCallbackData { sempahore in
            sempahore.signal()
        }
        
        do {
            let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                                                hostResolver: hostResolver,
                                                callbackData: clientBootstrapCallbackData,
                                                allocator: allocator)
            bootstrap.enableBlockingShutDown()
            let options = TlsContextOptions(defaultClientWithAllocator: allocator)
            let context = try TlsContext(options: options, mode: .client, allocator: allocator)
            let staticConfig = MockCredentialsProviderStaticConfigOptions(accessKey: accessKey,
                                                                    secret: secret,
                                                                    sessionToken: sessionToken)
            let provider = try CRTAWSCredentialsProvider(fromStatic: staticConfig, allocator: allocator)
            let config = MockCredentialsProviderSTSConfig(bootstrap: bootstrap,
                                                          tlsContext: context,
                                                          credentialsProvider: provider,
                                                          roleArn: "invalid-role-arn",
                                                          sessionName: "test-session",
                                                          durationSeconds: 10)
            _ = try CRTAWSCredentialsProvider(fromSTS: config)
        } catch let err {
            let awsErr = err as? AWSCommonRuntimeError
            XCTAssertEqual(awsErr?.code, 34)
        }
    }
    
    func testCreateDestroyEcsMissingCreds() {
        let elgShutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }
        
        let resolverShutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }
        
        let elg = EventLoopGroup(threadCount: 0, allocator: allocator, shutDownOptions: elgShutDownOptions)
        let hostResolver = DefaultHostResolver(eventLoopGroup: elg,
                                               maxHosts: 8,
                                               maxTTL: 30,
                                               allocator: allocator,
                                               shutDownOptions: resolverShutDownOptions)
        
        let clientBootstrapCallbackData = ClientBootstrapCallbackData { sempahore in
            sempahore.signal()
        }
        
        do {
            let bootstrap = try ClientBootstrap(eventLoopGroup: elg,
                                                hostResolver: hostResolver,
                                                callbackData: clientBootstrapCallbackData,
                                                allocator: allocator)
            bootstrap.enableBlockingShutDown()
            let options = TlsContextOptions(defaultClientWithAllocator: allocator)
            let context = try TlsContext(options: options, mode: .client, allocator: allocator)
            let shutDownOptions = setUpShutDownOptions()
            let config = MockCredentialsProviderContainerConfig(bootstrap: bootstrap,
                                                                tlsContext: context,
                                                                shutDownOptions: shutDownOptions)
            let provider = try CRTAWSCredentialsProvider(fromContainer: config)
            let result = provider.getCredentials()
            result.then { (result) in
                switch result {
                case .failure(let error):
                    XCTAssertNotNil(error)
                    self.expectation.fulfill()
                case .success(let credentials):
                    print(credentials)
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        } catch {
            XCTFail()
        }
    }
}

struct MockCredentialsProviderProfileOptions: CRTCredentialsProviderProfileOptions {
    var shutdownOptions: CRTCredentialsProviderShutdownOptions?
    
    var configFileNameOverride: String?
    
    var profileFileNameOverride: String?
    
    var credentialsFileNameOverride: String?
    
    init(configFileNameOverride: String? = nil,
         profileFileNameOverride: String? = nil,
         credentialsFileNameOverride: String? = nil,
         shutdownOptions: CRTCredentialsProviderShutdownOptions? = nil) {
        self.configFileNameOverride = configFileNameOverride
        self.profileFileNameOverride = profileFileNameOverride
        self.credentialsFileNameOverride = credentialsFileNameOverride
        self.shutdownOptions = shutdownOptions
    }
}

struct MockCredentialsProviderStaticConfigOptions: CRTCredentialsProviderStaticConfigOptions {
    public var accessKey: String
    public var secret: String
    public var sessionToken: String?
    public var shutDownOptions: CRTCredentialsProviderShutdownOptions?
    
    public init(accessKey: String,
                secret: String,
                sessionToken: String? = nil,
                shutDownOptions: CRTCredentialsProviderShutdownOptions? = nil) {
        self.accessKey = accessKey
        self.secret = secret
        self.sessionToken = sessionToken
        self.shutDownOptions = shutDownOptions
    }
}

public struct MockCredentialsProviderChainDefaultConfig: CRTCredentialsProviderChainDefaultConfig {
    public var shutDownOptions: CRTCredentialsProviderShutdownOptions?
    public var bootstrap: ClientBootstrap
    
    public init(bootstrap: ClientBootstrap,
                shutDownOptions: CRTCredentialsProviderShutdownOptions? = nil) {
        self.bootstrap = bootstrap
        self.shutDownOptions = shutDownOptions
    }
}

struct MockCredentialsProviderWebIdentityConfig: CRTCredentialsProviderWebIdentityConfig {
    var shutDownOptions: CRTCredentialsProviderShutdownOptions?
    var bootstrap: ClientBootstrap
    var tlsContext: TlsContext
    
    init(bootstrap: ClientBootstrap,
                tlsContext: TlsContext,
                shutDownOptions: CRTCredentialsProviderShutdownOptions? = nil) {
        self.bootstrap = bootstrap
        self.tlsContext = tlsContext
        self.shutDownOptions = shutDownOptions
    }
}

struct MockCredentialsProviderSTSConfig: CRTCredentialsProviderSTSConfig {
    var shutDownOptions: CRTCredentialsProviderShutdownOptions?
    var bootstrap: ClientBootstrap
    var tlsContext: TlsContext
    var credentialsProvider: CRTAWSCredentialsProvider
    var roleArn: String
    var sessionName: String
    var durationSeconds: UInt16
    
    init(bootstrap: ClientBootstrap,
         tlsContext: TlsContext,
         credentialsProvider: CRTAWSCredentialsProvider,
         roleArn: String,
         sessionName: String,
         durationSeconds: UInt16,
         shutDownOptions: CRTCredentialsProviderShutdownOptions? = nil) {
        self.bootstrap = bootstrap
        self.tlsContext = tlsContext
        self.credentialsProvider = credentialsProvider
        self.roleArn = roleArn
        self.sessionName = sessionName
        self.durationSeconds = durationSeconds
        self.shutDownOptions = shutDownOptions
    }
}

struct MockCredentialsProviderContainerConfig: CRTCredentialsProviderContainerConfig {
    var shutDownOptions: CRTCredentialsProviderShutdownOptions?
    var bootstrap: ClientBootstrap
    var tlsContext: TlsContext
    var authToken: String?
    var pathAndQuery: String?
    var host: String?
    
    init(bootstrap: ClientBootstrap,
         tlsContext: TlsContext,
         authToken: String? = nil,
         pathAndQuery: String? = nil,
         host: String? = nil,
         shutDownOptions: CRTCredentialsProviderShutdownOptions? = nil) {
        self.bootstrap = bootstrap
        self.tlsContext = tlsContext
        self.authToken = authToken
        self.pathAndQuery = pathAndQuery
        self.host = host
        self.shutDownOptions = shutDownOptions
    }
}
