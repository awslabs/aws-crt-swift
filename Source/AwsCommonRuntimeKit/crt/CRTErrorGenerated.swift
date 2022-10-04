// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.
// This file is generated using Script/CRTErrorGenerator.swift.
// Do not modify this file.

import AwsCCommon

/// Error type for CRT errors thrown from C code
public enum CRTError: Int32, Error {

    case unknownErrorCode = -1

    /// AWS-C-COMMON
    case oom = 1
    case noSpace = 2
    case unknown = 3
    case shortBuffer = 4
    case overflowDetected = 5
    case unsupportedOperation = 6
    case invalidBufferSize = 7
    case invalidHexStr = 8
    case invalidBase64Str = 9
    case invalidIndex = 10
    case threadInvalidSettings = 11
    case threadInsufficientResource = 12
    case threadNoPermissions = 13
    case threadNotJoinable = 14
    case threadNoSuchThreadId = 15
    case threadDeadlockDetected = 16
    case mutexNotInit = 17
    case mutexTimeout = 18
    case mutexCallerNotOwner = 19
    case mutexFailed = 20
    case conditionVariableInitFailed = 21
    case conditionVariableTimedOut = 22
    case conditionVariableUnknown = 23
    case clockFailure = 24
    case listEmpty = 25
    case destCopyTooSmall = 26
    case listExceedsMaxSize = 27
    case listStaticModeCantShrink = 28
    case priorityQueueFull = 29
    case priorityQueueEmpty = 30
    case priorityQueueBadNode = 31
    case hashTableItemNotFound = 32
    case invalidDateStr = 33
    case invalidArgument = 34
    case randomGenFailed = 35
    case malformedInputString = 36
    case unimplemented = 37
    case invalidState = 38
    case environmentGet = 39
    case environmentSet = 40
    case environmentUnset = 41
    case streamUnseekable = 42
    case noPermission = 43
    case fileInvalidPath = 44
    case maxFdsExceeded = 45
    case sysCallFailure = 46
    case cStringBufferNotNullTerminated = 47
    case stringMatchNotFound = 48
    case divideByZero = 49
    case invalidFileHandle = 50
    case operationInterrupted = 51
    case directoryNotEmpty = 52
    case platformNotSupported = 53

    /// AWS-C-IO
    case ioChannelCantAcceptInput = 1024
    case ioChannelUnknownMessageType = 1025
    case ioChannelReadWouldExceedWindow = 1026
    case ioEventLoopAlreadyAssigned = 1027
    case ioEventLoopShutdown = 1028
    case ioTlsNegotiationFailure = 1029
    case ioTlsNotNegotiated = 1030
    case ioTlsWriteFailure = 1031
    case ioTlsAlertReceived = 1032
    case ioTlsCtxError = 1033
    case ioTlsVersionUnsupported = 1034
    case ioTlsCipherPrefUnsupported = 1035
    case ioMissingAlpnMessage = 1036
    case ioUnhandledAlpnProtocolMessage = 1037
    case ioFileValidationFailure = 1038
    case ioEventLoopThreadOnly = 1039
    case ioAlreadySubscribed = 1040
    case ioNotSubscribed = 1041
    case ioOperationCancelled = 1042
    case ioReadWouldBlock = 1043
    case ioBrokenPipe = 1044
    case ioSocketUnsupportedAddressFamily = 1045
    case ioSocketInvalidOperationForType = 1046
    case ioSocketConnectionRefused = 1047
    case ioSocketTimeout = 1048
    case ioSocketNoRouteToHost = 1049
    case ioSocketNetworkDown = 1050
    case ioSocketClosed = 1051
    case ioSocketNotConnected = 1052
    case ioSocketInvalidOptions = 1053
    case ioSocketAddressInUse = 1054
    case ioSocketInvalidAddress = 1055
    case ioSocketIllegalOperationForState = 1056
    case ioSocketConnectAborted = 1057
    case ioDnsQueryFailed = 1058
    case ioDnsInvalidName = 1059
    case ioDnsNoAddressForHost = 1060
    case ioDnsHostRemovedFromCache = 1061
    case ioStreamInvalidSeekPosition = 1062
    case ioStreamReadFailed = 1063
    case deprecatedIoInvalidFileHandle = 1064
    case ioSharedLibraryLoadFailure = 1065
    case ioSharedLibraryFindSymbolFailure = 1066
    case ioTlsNegotiationTimeout = 1067
    case ioTlsAlertNotGraceful = 1068
    case ioMaxRetriesExceeded = 1069
    case ioRetryPermissionDenied = 1070
    case ioTlsDigestAlgorithmUnsupported = 1071
    case ioTlsSignatureAlgorithmUnsupported = 1072
    case pkcs11VersionUnsupported = 1073
    case pkcs11TokenNotFound = 1074
    case pkcs11KeyNotFound = 1075
    case pkcs11KeyTypeUnsupported = 1076
    case pkcs11UnknownCryptokiReturnValue = 1077
    case pkcs11CkrCancel = 1078
    case pkcs11CkrHostMemory = 1079
    case pkcs11CkrSlotIdInvalid = 1080
    case pkcs11CkrGeneralError = 1081
    case pkcs11CkrFunctionFailed = 1082
    case pkcs11CkrArgumentsBad = 1083
    case pkcs11CkrNoEvent = 1084
    case pkcs11CkrNeedToCreateThreads = 1085
    case pkcs11CkrCantLock = 1086
    case pkcs11CkrAttributeReadOnly = 1087
    case pkcs11CkrAttributeSensitive = 1088
    case pkcs11CkrAttributeTypeInvalid = 1089
    case pkcs11CkrAttributeValueInvalid = 1090
    case pkcs11CkrActionProhibited = 1091
    case pkcs11CkrDataInvalid = 1092
    case pkcs11CkrDataLenRange = 1093
    case pkcs11CkrDeviceError = 1094
    case pkcs11CkrDeviceMemory = 1095
    case pkcs11CkrDeviceRemoved = 1096
    case pkcs11CkrEncryptedDataInvalid = 1097
    case pkcs11CkrEncryptedDataLenRange = 1098
    case pkcs11CkrFunctionCanceled = 1099
    case pkcs11CkrFunctionNotParallel = 1100
    case pkcs11CkrFunctionNotSupported = 1101
    case pkcs11CkrKeyHandleInvalid = 1102
    case pkcs11CkrKeySizeRange = 1103
    case pkcs11CkrKeyTypeInconsistent = 1104
    case pkcs11CkrKeyNotNeeded = 1105
    case pkcs11CkrKeyChanged = 1106
    case pkcs11CkrKeyNeeded = 1107
    case pkcs11CkrKeyIndigestible = 1108
    case pkcs11CkrKeyFunctionNotPermitted = 1109
    case pkcs11CkrKeyNotWrappable = 1110
    case pkcs11CkrKeyUnextractable = 1111
    case pkcs11CkrMechanismInvalid = 1112
    case pkcs11CkrMechanismParamInvalid = 1113
    case pkcs11CkrObjectHandleInvalid = 1114
    case pkcs11CkrOperationActive = 1115
    case pkcs11CkrOperationNotInitialized = 1116
    case pkcs11CkrPinIncorrect = 1117
    case pkcs11CkrPinInvalid = 1118
    case pkcs11CkrPinLenRange = 1119
    case pkcs11CkrPinExpired = 1120
    case pkcs11CkrPinLocked = 1121
    case pkcs11CkrSessionClosed = 1122
    case pkcs11CkrSessionCount = 1123
    case pkcs11CkrSessionHandleInvalid = 1124
    case pkcs11CkrSessionParallelNotSupported = 1125
    case pkcs11CkrSessionReadOnly = 1126
    case pkcs11CkrSessionExists = 1127
    case pkcs11CkrSessionReadOnlyExists = 1128
    case pkcs11CkrSessionReadWriteSoExists = 1129
    case pkcs11CkrSignatureInvalid = 1130
    case pkcs11CkrSignatureLenRange = 1131
    case pkcs11CkrTemplateIncomplete = 1132
    case pkcs11CkrTemplateInconsistent = 1133
    case pkcs11CkrTokenNotPresent = 1134
    case pkcs11CkrTokenNotRecognized = 1135
    case pkcs11CkrTokenWriteProtected = 1136
    case pkcs11CkrUnwrappingKeyHandleInvalid = 1137
    case pkcs11CkrUnwrappingKeySizeRange = 1138
    case pkcs11CkrUnwrappingKeyTypeInconsistent = 1139
    case pkcs11CkrUserAlreadyLoggedIn = 1140
    case pkcs11CkrUserNotLoggedIn = 1141
    case pkcs11CkrUserPinNotInitialized = 1142
    case pkcs11CkrUserTypeInvalid = 1143
    case pkcs11CkrUserAnotherAlreadyLoggedIn = 1144
    case pkcs11CkrUserTooManyTypes = 1145
    case pkcs11CkrWrappedKeyInvalid = 1146
    case pkcs11CkrWrappedKeyLenRange = 1147
    case pkcs11CkrWrappingKeyHandleInvalid = 1148
    case pkcs11CkrWrappingKeySizeRange = 1149
    case pkcs11CkrWrappingKeyTypeInconsistent = 1150
    case pkcs11CkrRandomSeedNotSupported = 1151
    case pkcs11CkrRandomNoRng = 1152
    case pkcs11CkrDomainParamsInvalid = 1153
    case pkcs11CkrCurveNotSupported = 1154
    case pkcs11CkrBufferTooSmall = 1155
    case pkcs11CkrSavedStateInvalid = 1156
    case pkcs11CkrInformationSensitive = 1157
    case pkcs11CkrStateUnsaveable = 1158
    case pkcs11CkrCryptokiNotInitialized = 1159
    case pkcs11CkrCryptokiAlreadyInitialized = 1160
    case pkcs11CkrMutexBad = 1161
    case pkcs11CkrMutexNotLocked = 1162
    case pkcs11CkrNewPinMode = 1163
    case pkcs11CkrNextOtp = 1164
    case pkcs11CkrExceededMaxIterations = 1165
    case pkcs11CkrFipsSelfTestFailed = 1166
    case pkcs11CkrLibraryLoadFailed = 1167
    case pkcs11CkrPinTooWeak = 1168
    case pkcs11CkrPublicKeyInvalid = 1169
    case pkcs11CkrFunctionRejected = 1170
    case ioPinnedEventLoopMismatch = 1171
    case pkcs11EncodingError = 1172
    case ioTlsDefaultTrustStoreNotFound = 1173

    /// AWS-C-HTTP
    case httpUnknown = 2048
    case httpHeaderNotFound = 2049
    case httpInvalidHeaderField = 2050
    case httpInvalidHeaderName = 2051
    case httpInvalidHeaderValue = 2052
    case httpInvalidMethod = 2053
    case httpInvalidPath = 2054
    case httpInvalidStatusCode = 2055
    case httpMissingBodyStream = 2056
    case httpInvalidBodyStream = 2057
    case httpConnectionClosed = 2058
    case httpSwitchedProtocols = 2059
    case httpUnsupportedProtocol = 2060
    case httpReactionRequired = 2061
    case httpDataNotAvailable = 2062
    case httpOutgoingStreamLengthIncorrect = 2063
    case httpCallbackFailure = 2064
    case httpWebsocketUpgradeFailure = 2065
    case httpWebsocketCloseFrameSent = 2066
    case httpWebsocketIsMidchannelHandler = 2067
    case httpConnectionManagerInvalidStateForAcquire = 2068
    case httpConnectionManagerVendedConnectionUnderflow = 2069
    case httpServerClosed = 2070
    case httpProxyConnectFailed = 2071
    case httpConnectionManagerShuttingDown = 2072
    case httpChannelThroughputFailure = 2073
    case httpProtocolError = 2074
    case httpStreamIdsExhausted = 2075
    case httpGoawayReceived = 2076
    case httpRstStreamReceived = 2077
    case httpRstStreamSent = 2078
    case httpStreamNotActivated = 2079
    case httpStreamHasCompleted = 2080
    case httpProxyStrategyNtlmChallengeTokenMissing = 2081
    case httpProxyStrategyTokenRetrievalFailure = 2082
    case httpProxyConnectFailedRetryable = 2083
    case httpProtocolSwitchFailure = 2084
    case httpMaxConcurrentStreamsExceeded = 2085
    case httpStreamManagerShuttingDown = 2086
    case httpStreamManagerConnectionAcquireFailure = 2087
    case httpStreamManagerUnexpectedHttpVersion = 2088

    /// AWS-C-COMPRESSION
    case compressionUnknownSymbol = 3072

    /// AWS-C-EVENTSTREAM

    /// AWS-C-AUTH
    case authSigningUnsupportedAlgorithm = 6144
    case authSigningMismatchedConfiguration = 6145
    case authSigningNoCredentials = 6146
    case authSigningIllegalRequestQueryParam = 6147
    case authSigningIllegalRequestHeader = 6148
    case authSigningInvalidConfiguration = 6149
    case authCredentialsProviderInvalidEnvironment = 6150
    case authCredentialsProviderInvalidDelegate = 6151
    case authCredentialsProviderProfileSourceFailure = 6152
    case authCredentialsProviderImdsSourceFailure = 6153
    case authCredentialsProviderStsSourceFailure = 6154
    case authCredentialsProviderHttpStatusFailure = 6155
    case authProviderParserUnexpectedResponse = 6156
    case authCredentialsProviderEcsSourceFailure = 6157
    case authCredentialsProviderX509SourceFailure = 6158
    case authCredentialsProviderProcessSourceFailure = 6159
    case authCredentialsProviderStsWebIdentitySourceFailure = 6160
    case authSigningUnsupportedSignatureType = 6161
    case authSigningMissingPreviousSignature = 6162
    case authSigningInvalidCredentials = 6163
    case authCanonicalRequestMismatch = 6164
    case authSigv4aSignatureValidationFailure = 6165
    case authCredentialsProviderCognitoSourceFailure = 6166

    /// AWS-C-CAL
    case calSignatureValidationFailed = 7168
    case calMissingRequiredKeyComponent = 7169
    case calInvalidKeyLengthForAlgorithm = 7170
    case calUnknownObjectIdentifier = 7171
    case calMalformedAsn1Encountered = 7172
    case calMismatchedDerType = 7173
    case calUnsupportedAlgorithm = 7174

    /// AWS-C-SDKUTILS
    case sdkutilsGeneral = 15360
    case sdkutilsParseFatal = 15361
    case sdkutilsParseRecoverable = 15362
}
