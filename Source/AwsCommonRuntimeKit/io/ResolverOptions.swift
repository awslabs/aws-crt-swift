//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

class ResolverOptions {
	let host: AWSString
	let resolver: HostResolver
	let continuation: HostResolvedContinuation

	//Todo: can we just do AWSString = AWSString or make a copy?
	init(resolver: HostResolver, host: AWSString, continuation: HostResolvedContinuation) {
		self.host = host
		self.continuation = continuation
		self.resolver = resolver
	}
}
