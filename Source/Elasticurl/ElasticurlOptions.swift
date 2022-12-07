//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCommonRuntimeKit

// swiftlint:disable identifier_name
public struct ElasticurlOptions {
    static let caCert = AWSCLIOption(name: "cacert",
                                     hasArg: .required,
                                     flag: nil,
                                     val: "a")
    static let caPath = AWSCLIOption(name: "capath",
                                     hasArg: .required,
                                     flag: nil,
                                     val: "b")
    static let cert = AWSCLIOption(name: "cert",
                                   hasArg: .required,
                                   flag: nil,
                                   val: "c")
    static let key = AWSCLIOption(name: "key",
                                  hasArg: .required,
                                  flag: nil,
                                  val: "e")
    static let connectTimeout = AWSCLIOption(name: "connect-timeout",
                                             hasArg: .required,
                                             flag: nil,
                                             val: "f")
    static let header = AWSCLIOption(name: "header",
                                     hasArg: .required,
                                     flag: nil,
                                     val: "H")
    static let data = AWSCLIOption(name: "data",
                                   hasArg: .required,
                                   flag: nil,
                                   val: "d")
    static let dataFile = AWSCLIOption(name: "data-file",
                                       hasArg: .required,
                                       flag: nil,
                                       val: "g")
    static let method = AWSCLIOption(name: "method",
                                     hasArg: .required,
                                     flag: nil,
                                     val: "M")
    static let get = AWSCLIOption(name: "get",
                                  hasArg: .none,
                                  flag: nil,
                                  val: "G")
    static let post = AWSCLIOption(name: "post",
                                   hasArg: .none,
                                   flag: nil,
                                   val: "P")
    static let head = AWSCLIOption(name: "head",
                                   hasArg: .none,
                                   flag: nil,
                                   val: "I")
    static let signingLib = AWSCLIOption(name: "signing-lib",
                                         hasArg: .required,
                                         flag: nil,
                                         val: "j")
    static let include = AWSCLIOption(name: "include",
                                      hasArg: .none,
                                      flag: nil,
                                      val: "i")
    static let insecure = AWSCLIOption(name: "insecure",
                                       hasArg: .none,
                                       flag: nil,
                                       val: "k")
    static let signingFunc = AWSCLIOption(name: "signing-func",
                                          hasArg: .required,
                                          flag: nil,
                                          val: "l")
    static let signingContext = AWSCLIOption(name: "signing-context",
                                             hasArg: .required,
                                             flag: nil,
                                             val: "m")
    static let output = AWSCLIOption(name: "output",
                                     hasArg: .required,
                                     flag: nil,
                                     val: "o")
    static let trace = AWSCLIOption(name: "trace",
                                    hasArg: .required,
                                    flag: nil,
                                    val: "t")
    static let verbose = AWSCLIOption(name: "verbose",
                                      hasArg: .required,
                                      flag: nil,
                                      val: "v")
    static let version = AWSCLIOption(name: "version",
                                      hasArg: .none,
                                      flag: nil,
                                      val: "V")
    static let http2 = AWSCLIOption(name: "http2",
                                    hasArg: .none,
                                    flag: nil,
                                    val: "w")
    static let http1_1 = AWSCLIOption(name: "http1_1",
                                      hasArg: .none,
                                      flag: nil,
                                      val: "W")
    static let help = AWSCLIOption(name: "help",
                                   hasArg: .none,
                                   flag: nil,
                                   val: "h")
    static let lastOption = AWSCLIOption(name: "",
                                         hasArg: .none,
                                         flag: nil,
                                         val: "0")
}
