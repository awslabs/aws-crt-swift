//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

enum HttpConnectionError: Error {
    case success
    case failure
}

extension HttpConnectionError: RawRepresentable {
    var rawValue: Int32 {
        switch self {
        case .success: return 0
        case .failure: return 1
        }
    }
    
    init(rawValue: Int32) {
        switch rawValue {
        case 0: self = .success
        case 1: self = .failure
        default:
            self = .failure
        }
    }
}
