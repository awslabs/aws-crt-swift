//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCommonRuntimeKit

//swiftlint:disable identifier_name
public struct ElasticurlOptions {
    public static let caCert = AWSCLIOption(name: "cacert",
                                            hasArg: .required,
                                            flag: nil,
                                            val: "a")
    public static let caPath = AWSCLIOption(name: "capath",
                                            hasArg: .required,
                                            flag: nil,
                                            val: "b")
    public static let cert = AWSCLIOption(name: "cert",
                                          hasArg: .required,
                                          flag: nil,
                                          val: "c")
    public static let key = AWSCLIOption(name: "key",
                                         hasArg: .required,
                                         flag: nil,
                                         val: "e")
    public static let connectTimeout = AWSCLIOption(name: "connect-timeout",
                                                    hasArg: .required,
                                                    flag: nil,
                                                    val: "f")
    public static let header = AWSCLIOption(name: "header",
                                            hasArg: .required,
                                            flag: nil,
                                            val: "H")
    public static let data = AWSCLIOption(name: "data",
                                          hasArg: .required,
                                          flag: nil,
                                          val: "d")
    public static let dataFile = AWSCLIOption(name: "data-file",
                                              hasArg: .required,
                                              flag: nil,
                                              val: "g")
    public static let method = AWSCLIOption(name: "method",
                                            hasArg: .required,
                                            flag: nil,
                                            val: "M")
    public static let get = AWSCLIOption(name: "get",
                                         hasArg: .none,
                                         flag: nil,
                                         val: "G")
    public static let post = AWSCLIOption(name: "post",
                                          hasArg: .none,
                                          flag: nil,
                                          val: "P")
    public static let head = AWSCLIOption(name: "head",
                                          hasArg: .none,
                                          flag: nil,
                                          val: "I")
    public static let signingLib = AWSCLIOption(name: "signing-lib",
                                                hasArg: .required,
                                                flag: nil,
                                                val: "j")
    public static let include = AWSCLIOption(name: "include",
                                             hasArg: .none,
                                             flag: nil,
                                             val: "i")
    public static let insecure = AWSCLIOption(name: "insecure",
                                              hasArg: .none,
                                              flag: nil,
                                              val: "k")
    public static let signingFunc = AWSCLIOption(name: "signing-func",
                                                 hasArg: .required,
                                                 flag: nil,
                                                 val: "l")
    public static let signingContext = AWSCLIOption(name: "signing-context",
                                                    hasArg: .required,
                                                    flag: nil,
                                                    val: "m")
    public static let output = AWSCLIOption(name: "output",
                                            hasArg: .required,
                                            flag: nil,
                                            val: "o")
    public static let trace = AWSCLIOption(name: "trace",
                                           hasArg: .required,
                                           flag: nil,
                                           val: "t")
    public static let verbose = AWSCLIOption(name: "verbose",
                                             hasArg: .required,
                                             flag: nil,
                                             val: "v")
    public static let version = AWSCLIOption(name: "version",
                                             hasArg: .none,
                                             flag: nil,
                                             val: "V")
    public static let http2 = AWSCLIOption(name: "http2",
                                           hasArg: .none,
                                           flag: nil,
                                           val: "w")
    public static let http1_1 = AWSCLIOption(name: "http1_1",
                                             hasArg: .none,
                                             flag: nil,
                                             val: "W")
    public static let help = AWSCLIOption(name: "help",
                                          hasArg: .none,
                                          flag: nil,
                                          val: "h")
    public static let lastOption = AWSCLIOption(name: "",
                                                hasArg: .none,
                                                flag: nil,
                                                val: "0")
}
