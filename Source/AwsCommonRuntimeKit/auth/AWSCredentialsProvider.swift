//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCAuth

//open cuz can be subclassed with credentials provider to implement for runtime specific usage.
open class AWSCredentialsProvider: CredentialsProvider {
    public var allocator: Allocator
    public var rawValue: UnsafeMutablePointer<aws_credentials_provider>

    required public init(connection: UnsafeMutablePointer<aws_credentials_provider>,
                         allocator: Allocator = defaultAllocator) {
        self.allocator = allocator
        self.rawValue = connection
    }

    func getCredentials(credentialCallBackData: CredentialProviderCallbackData) {
        let data = UnsafeMutablePointer<CredentialProviderCallbackData>.allocate(capacity: 1)
        data.initialize(to: credentialCallBackData)

        defer {
            data.deinitialize(count: 1)
            data.deallocate()
        }
        aws_credentials_provider_get_credentials(rawValue, { (credentials, errorCode, userdata) -> Void in
            guard let userdata = userdata, let credentials = credentials else {
                return
            }

            let callback = userdata.bindMemory(to: CredentialProviderCallbackData.self, capacity: 1)
            callback.pointee.onCredentialsResolved(Credentials(rawValue: credentials), errorCode)

        }, data)
    }

    func createWrappedProvider(cProvider: UnsafeMutablePointer<aws_credentials_provider>,
                               allocator: Allocator) -> CredentialsProvider {
        let provider = AWSCredentialsProvider(connection: cProvider, allocator: allocator)
        return provider as CredentialsProvider
    }

    func createCredentialsProviderStatic(config: CredentialsProviderStaticConfigOptions) -> CredentialsProvider? {

        guard let provider = aws_credentials_provider_new_static(allocator.rawValue,
                                                                 config.rawValue) else { return nil }

        return createWrappedProvider(cProvider: provider, allocator: allocator)
    }

    func createCredentialsProviderEnvironment(shutdownOptions: AWSCredentialsProviderShutdownOptions)
        -> CredentialsProvider? {
        let options = UnsafeMutablePointer<aws_credentials_provider_environment_options>.allocate(capacity: 1)
        options.pointee = aws_credentials_provider_environment_options(
            shutdown_options: shutdownOptions.rawValue.pointee)
        guard let provider = aws_credentials_provider_new_environment(allocator.rawValue,
                                                                      options) else {return nil}
        defer {
            options.deallocate()
        }
        return createWrappedProvider(cProvider: provider, allocator: allocator)
    }

    func createCredentialsProviderProfile(profileOptions: AWSCredentialsProviderProfileOptions)
        -> CredentialsProvider? {
        let options = UnsafeMutablePointer<aws_credentials_provider_profile_options>.allocate(capacity: 1)
        options.pointee = aws_credentials_provider_profile_options(shutdown_options: profileOptions.shutdownOptions.rawValue.pointee,
                                               profile_name_override: profileOptions.profileFileNameOverride.awsByteCursor,
                                               config_file_name_override: profileOptions.configFileNameOverride.awsByteCursor,
                                               credentials_file_name_override: profileOptions.credentialsFileNameOverride.awsByteCursor,
                                               bootstrap: nil,
                                               function_table: nil)
        guard let provider = aws_credentials_provider_new_profile(allocator.rawValue,
                                                                  options) else {return nil}
        defer {
            options.deallocate()
        }
        return createWrappedProvider(cProvider: provider, allocator: allocator)
    }

    func createCredentialsProviderImds(imdsConfig: AWSCredentialsProviderImdsConfig) -> CredentialsProvider? {
        let options = UnsafeMutablePointer<aws_credentials_provider_imds_options>.allocate(capacity: 1)

        options.pointee = aws_credentials_provider_imds_options(shutdown_options: imdsConfig.shutdownOptions.rawValue.pointee,
                                                                bootstrap: imdsConfig.bootstrap.rawValue,
                                                                imds_version: IMDS_PROTOCOL_V2,
                                                                function_table: nil)
        guard let provider = aws_credentials_provider_new_imds(allocator.rawValue, options) else {return nil}

        return createWrappedProvider(cProvider: provider, allocator: allocator)
    }

    func createCredentialsProviderChain() -> CredentialsProvider? {
        //TODO: pass in array of providers in the options struct
        guard let provider = aws_credentials_provider_new_chain(allocator.rawValue,
                                                                nil) else {return nil}
        return createWrappedProvider(cProvider: provider, allocator: allocator)
    }

    deinit {
        aws_credentials_provider_release(rawValue)
        rawValue.deallocate()
    }
}
