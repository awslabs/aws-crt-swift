//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

class ResolverOptions {
	let host: AWSString
	let resolver: HostResolver
	let onResolved: OnHostResolved

	init(resolver: HostResolver, host: AWSString, onResolved: @escaping OnHostResolved) {
		self.host = host
		self.onResolved = onResolved
		self.resolver = resolver
	}
}
