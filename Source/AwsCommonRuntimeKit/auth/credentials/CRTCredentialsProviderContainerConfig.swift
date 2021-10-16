//
//  File.swift
//  File
//
//  Created by Stone, Nicki on 10/15/21.
//

public protocol CRTCredentialsProviderContainerConfig {
    var shutDownOptions: CRTCredentialsProviderShutdownOptions? {get set}
    var bootstrap: ClientBootstrap {get set}
    var tlsContext: TlsContext {get set}
    var authToken: String {get set}
    var pathAndQuery: String {get set}
    var host: String {get set}
}
