import AwsCCommon
import AwsCIo

public typealias HostAddress = aws_host_address
public typealias OnHostResolved = (HostResolver, [HostAddress], Int32) -> Void

public protocol HostResolver : class {
  var rawValue: aws_host_resolver { get set }
  var config: aws_host_resolution_config { get }
  func resolve(host: String, onResolved: @escaping OnHostResolved) throws
}

public final class DefaultHostResolver : HostResolver {
  public var rawValue = aws_host_resolver()
  public var config: aws_host_resolution_config
  private let allocator: Allocator

  public init(eventLoopGroup elg: EventLoopGroup, maxHosts: Int, maxTTL: Int, allocator: Allocator = defaultAllocator) throws {
    self.allocator = allocator

    if (aws_host_resolver_init_default(&self.rawValue, allocator.rawValue, maxHosts, &elg.rawValue) != AWS_OP_SUCCESS) {
      throw AwsCommonRuntimeError()
    }

    self.config = aws_host_resolution_config(
      impl: aws_default_dns_resolve,
      max_ttl: maxTTL,
      impl_data: nil
    )
  }

  deinit {
    aws_host_resolver_clean_up(&self.rawValue)
  }

  public func resolve(host: String, onResolved callback: @escaping OnHostResolved) throws {
    let options = ResolverOptions(resolver: self,
                                  host: AwsString(host, allocator: self.allocator),
                                  onResolved: callback)
    let unmanagedOptions = Unmanaged.passRetained(options)

    if (aws_host_resolver_resolve_host(&self.rawValue,
                                       options.host.rawValue,
                                       onHostResolved,
                                       &self.config,
                                       unmanagedOptions.toOpaque()) != AWS_OP_SUCCESS) {
      // We have an unbalanced retain on unmanagedOptions, need to release it!
      defer { unmanagedOptions.release() }
      throw AwsCommonRuntimeError()
    }
  }
}

private func onHostResolved(_ resolver: UnsafeMutablePointer<aws_host_resolver>!,
                            _ hostName: UnsafePointer<aws_string>!,
                            _ errorCode: Int32,
                            _ hostAddresses: UnsafePointer<aws_array_list>!,
                            _ userData: UnsafeMutableRawPointer!) {
  // Consumes the unbalanced retain that was made to get the value here
  let options: ResolverOptions = Unmanaged.fromOpaque(userData).takeRetainedValue()

  let length = aws_array_list_length(hostAddresses)
  var addresses: [HostAddress] = Array(repeating: HostAddress(), count: length)

  for i  in 0..<length {
    var address: UnsafeMutableRawPointer! = nil
    aws_array_list_get_at_ptr(hostAddresses, &address, i)
    addresses[i] = address.bindMemory(to: HostAddress.self, capacity: 1).pointee
  }

  options.onResolved(options.resolver, addresses, errorCode)
}

fileprivate class ResolverOptions {
  let host: AwsString
  let resolver: HostResolver
  let onResolved: OnHostResolved

  init(resolver: HostResolver, host: AwsString, onResolved: @escaping OnHostResolved) {
    self.host = host
    self.onResolved = onResolved
    self.resolver = resolver
  }
}
