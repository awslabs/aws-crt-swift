// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.
// This file is generated using Script/CRTErrorGenerator.swift.
// Do not modify this file.

import AwsCCommon

public enum CRTError: Int32, Error {

    case UNKNOWN_ERROR_CODE = -1

    /// AWS-C-COMMON
    case AWS_ERROR_SUCCESS = 0
    case AWS_ERROR_OOM = 1
    case AWS_ERROR_NO_SPACE = 2
    case AWS_ERROR_UNKNOWN = 3
    case AWS_ERROR_SHORT_BUFFER = 4
    case AWS_ERROR_OVERFLOW_DETECTED = 5
    case AWS_ERROR_UNSUPPORTED_OPERATION = 6
    case AWS_ERROR_INVALID_BUFFER_SIZE = 7
    case AWS_ERROR_INVALID_HEX_STR = 8
    case AWS_ERROR_INVALID_BASE64_STR = 9
    case AWS_ERROR_INVALID_INDEX = 10
    case AWS_ERROR_THREAD_INVALID_SETTINGS = 11
    case AWS_ERROR_THREAD_INSUFFICIENT_RESOURCE = 12
    case AWS_ERROR_THREAD_NO_PERMISSIONS = 13
    case AWS_ERROR_THREAD_NOT_JOINABLE = 14
    case AWS_ERROR_THREAD_NO_SUCH_THREAD_ID = 15
    case AWS_ERROR_THREAD_DEADLOCK_DETECTED = 16
    case AWS_ERROR_MUTEX_NOT_INIT = 17
    case AWS_ERROR_MUTEX_TIMEOUT = 18
    case AWS_ERROR_MUTEX_CALLER_NOT_OWNER = 19
    case AWS_ERROR_MUTEX_FAILED = 20
    case AWS_ERROR_COND_VARIABLE_INIT_FAILED = 21
    case AWS_ERROR_COND_VARIABLE_TIMED_OUT = 22
    case AWS_ERROR_COND_VARIABLE_ERROR_UNKNOWN = 23
    case AWS_ERROR_CLOCK_FAILURE = 24
    case AWS_ERROR_LIST_EMPTY = 25
    case AWS_ERROR_DEST_COPY_TOO_SMALL = 26
    case AWS_ERROR_LIST_EXCEEDS_MAX_SIZE = 27
    case AWS_ERROR_LIST_STATIC_MODE_CANT_SHRINK = 28
    case AWS_ERROR_PRIORITY_QUEUE_FULL = 29
    case AWS_ERROR_PRIORITY_QUEUE_EMPTY = 30
    case AWS_ERROR_PRIORITY_QUEUE_BAD_NODE = 31
    case AWS_ERROR_HASHTBL_ITEM_NOT_FOUND = 32
    case AWS_ERROR_INVALID_DATE_STR = 33
    case AWS_ERROR_INVALID_ARGUMENT = 34
    case AWS_ERROR_RANDOM_GEN_FAILED = 35
    case AWS_ERROR_MALFORMED_INPUT_STRING = 36
    case AWS_ERROR_UNIMPLEMENTED = 37
    case AWS_ERROR_INVALID_STATE = 38
    case AWS_ERROR_ENVIRONMENT_GET = 39
    case AWS_ERROR_ENVIRONMENT_SET = 40
    case AWS_ERROR_ENVIRONMENT_UNSET = 41
    case AWS_ERROR_STREAM_UNSEEKABLE = 42
    case AWS_ERROR_NO_PERMISSION = 43
    case AWS_ERROR_FILE_INVALID_PATH = 44
    case AWS_ERROR_MAX_FDS_EXCEEDED = 45
    case AWS_ERROR_SYS_CALL_FAILURE = 46
    case AWS_ERROR_C_STRING_BUFFER_NOT_NULL_TERMINATED = 47
    case AWS_ERROR_STRING_MATCH_NOT_FOUND = 48
    case AWS_ERROR_DIVIDE_BY_ZERO = 49
    case AWS_ERROR_INVALID_FILE_HANDLE = 50
    case AWS_ERROR_OPERATION_INTERUPTED = 51
    case AWS_ERROR_DIRECTORY_NOT_EMPTY = 52
    case AWS_ERROR_PLATFORM_NOT_SUPPORTED = 53

    /// AWS-C-IO
    case AWS_IO_CHANNEL_ERROR_ERROR_CANT_ACCEPT_INPUT = 1024
    case AWS_IO_CHANNEL_UNKNOWN_MESSAGE_TYPE = 1025
    case AWS_IO_CHANNEL_READ_WOULD_EXCEED_WINDOW = 1026
    case AWS_IO_EVENT_LOOP_ALREADY_ASSIGNED = 1027
    case AWS_IO_EVENT_LOOP_SHUTDOWN = 1028
    case AWS_IO_TLS_ERROR_NEGOTIATION_FAILURE = 1029
    case AWS_IO_TLS_ERROR_NOT_NEGOTIATED = 1030
    case AWS_IO_TLS_ERROR_WRITE_FAILURE = 1031
    case AWS_IO_TLS_ERROR_ALERT_RECEIVED = 1032
    case AWS_IO_TLS_CTX_ERROR = 1033
    case AWS_IO_TLS_VERSION_UNSUPPORTED = 1034
    case AWS_IO_TLS_CIPHER_PREF_UNSUPPORTED = 1035
    case AWS_IO_MISSING_ALPN_MESSAGE = 1036
    case AWS_IO_UNHANDLED_ALPN_PROTOCOL_MESSAGE = 1037
    case AWS_IO_FILE_VALIDATION_FAILURE = 1038
    case AWS_ERROR_IO_EVENT_LOOP_THREAD_ONLY = 1039
    case AWS_ERROR_IO_ALREADY_SUBSCRIBED = 1040
    case AWS_ERROR_IO_NOT_SUBSCRIBED = 1041
    case AWS_ERROR_IO_OPERATION_CANCELLED = 1042
    case AWS_IO_READ_WOULD_BLOCK = 1043
    case AWS_IO_BROKEN_PIPE = 1044
    case AWS_IO_SOCKET_UNSUPPORTED_ADDRESS_FAMILY = 1045
    case AWS_IO_SOCKET_INVALID_OPERATION_FOR_TYPE = 1046
    case AWS_IO_SOCKET_CONNECTION_REFUSED = 1047
    case AWS_IO_SOCKET_TIMEOUT = 1048
    case AWS_IO_SOCKET_NO_ROUTE_TO_HOST = 1049
    case AWS_IO_SOCKET_NETWORK_DOWN = 1050
    case AWS_IO_SOCKET_CLOSED = 1051
    case AWS_IO_SOCKET_NOT_CONNECTED = 1052
    case AWS_IO_SOCKET_INVALID_OPTIONS = 1053
    case AWS_IO_SOCKET_ADDRESS_IN_USE = 1054
    case AWS_IO_SOCKET_INVALID_ADDRESS = 1055
    case AWS_IO_SOCKET_ILLEGAL_OPERATION_FOR_STATE = 1056
    case AWS_IO_SOCKET_CONNECT_ABORTED = 1057
    case AWS_IO_DNS_QUERY_FAILED = 1058
    case AWS_IO_DNS_INVALID_NAME = 1059
    case AWS_IO_DNS_NO_ADDRESS_FOR_HOST = 1060
    case AWS_IO_DNS_HOST_REMOVED_FROM_CACHE = 1061
    case AWS_IO_STREAM_INVALID_SEEK_POSITION = 1062
    case AWS_IO_STREAM_READ_FAILED = 1063
    case DEPRECATED_AWS_IO_INVALID_FILE_HANDLE = 1064
    case AWS_IO_SHARED_LIBRARY_LOAD_FAILURE = 1065
    case AWS_IO_SHARED_LIBRARY_FIND_SYMBOL_FAILURE = 1066
    case AWS_IO_TLS_NEGOTIATION_TIMEOUT = 1067
    case AWS_IO_TLS_ALERT_NOT_GRACEFUL = 1068
    case AWS_IO_MAX_RETRIES_EXCEEDED = 1069
    case AWS_IO_RETRY_PERMISSION_DENIED = 1070
    case AWS_IO_TLS_DIGEST_ALGORITHM_UNSUPPORTED = 1071
    case AWS_IO_TLS_SIGNATURE_ALGORITHM_UNSUPPORTED = 1072
    case AWS_ERROR_PKCS11_VERSION_UNSUPPORTED = 1073
    case AWS_ERROR_PKCS11_TOKEN_NOT_FOUND = 1074
    case AWS_ERROR_PKCS11_KEY_NOT_FOUND = 1075
    case AWS_ERROR_PKCS11_KEY_TYPE_UNSUPPORTED = 1076
    case AWS_ERROR_PKCS11_UNKNOWN_CRYPTOKI_RETURN_VALUE = 1077
    case AWS_ERROR_PKCS11_CKR_CANCEL = 1078
    case AWS_ERROR_PKCS11_CKR_HOST_MEMORY = 1079
    case AWS_ERROR_PKCS11_CKR_SLOT_ID_INVALID = 1080
    case AWS_ERROR_PKCS11_CKR_GENERAL_ERROR = 1081
    case AWS_ERROR_PKCS11_CKR_FUNCTION_FAILED = 1082
    case AWS_ERROR_PKCS11_CKR_ARGUMENTS_BAD = 1083
    case AWS_ERROR_PKCS11_CKR_NO_EVENT = 1084
    case AWS_ERROR_PKCS11_CKR_NEED_TO_CREATE_THREADS = 1085
    case AWS_ERROR_PKCS11_CKR_CANT_LOCK = 1086
    case AWS_ERROR_PKCS11_CKR_ATTRIBUTE_READ_ONLY = 1087
    case AWS_ERROR_PKCS11_CKR_ATTRIBUTE_SENSITIVE = 1088
    case AWS_ERROR_PKCS11_CKR_ATTRIBUTE_TYPE_INVALID = 1089
    case AWS_ERROR_PKCS11_CKR_ATTRIBUTE_VALUE_INVALID = 1090
    case AWS_ERROR_PKCS11_CKR_ACTION_PROHIBITED = 1091
    case AWS_ERROR_PKCS11_CKR_DATA_INVALID = 1092
    case AWS_ERROR_PKCS11_CKR_DATA_LEN_RANGE = 1093
    case AWS_ERROR_PKCS11_CKR_DEVICE_ERROR = 1094
    case AWS_ERROR_PKCS11_CKR_DEVICE_MEMORY = 1095
    case AWS_ERROR_PKCS11_CKR_DEVICE_REMOVED = 1096
    case AWS_ERROR_PKCS11_CKR_ENCRYPTED_DATA_INVALID = 1097
    case AWS_ERROR_PKCS11_CKR_ENCRYPTED_DATA_LEN_RANGE = 1098
    case AWS_ERROR_PKCS11_CKR_FUNCTION_CANCELED = 1099
    case AWS_ERROR_PKCS11_CKR_FUNCTION_NOT_PARALLEL = 1100
    case AWS_ERROR_PKCS11_CKR_FUNCTION_NOT_SUPPORTED = 1101
    case AWS_ERROR_PKCS11_CKR_KEY_HANDLE_INVALID = 1102
    case AWS_ERROR_PKCS11_CKR_KEY_SIZE_RANGE = 1103
    case AWS_ERROR_PKCS11_CKR_KEY_TYPE_INCONSISTENT = 1104
    case AWS_ERROR_PKCS11_CKR_KEY_NOT_NEEDED = 1105
    case AWS_ERROR_PKCS11_CKR_KEY_CHANGED = 1106
    case AWS_ERROR_PKCS11_CKR_KEY_NEEDED = 1107
    case AWS_ERROR_PKCS11_CKR_KEY_INDIGESTIBLE = 1108
    case AWS_ERROR_PKCS11_CKR_KEY_FUNCTION_NOT_PERMITTED = 1109
    case AWS_ERROR_PKCS11_CKR_KEY_NOT_WRAPPABLE = 1110
    case AWS_ERROR_PKCS11_CKR_KEY_UNEXTRACTABLE = 1111
    case AWS_ERROR_PKCS11_CKR_MECHANISM_INVALID = 1112
    case AWS_ERROR_PKCS11_CKR_MECHANISM_PARAM_INVALID = 1113
    case AWS_ERROR_PKCS11_CKR_OBJECT_HANDLE_INVALID = 1114
    case AWS_ERROR_PKCS11_CKR_OPERATION_ACTIVE = 1115
    case AWS_ERROR_PKCS11_CKR_OPERATION_NOT_INITIALIZED = 1116
    case AWS_ERROR_PKCS11_CKR_PIN_INCORRECT = 1117
    case AWS_ERROR_PKCS11_CKR_PIN_INVALID = 1118
    case AWS_ERROR_PKCS11_CKR_PIN_LEN_RANGE = 1119
    case AWS_ERROR_PKCS11_CKR_PIN_EXPIRED = 1120
    case AWS_ERROR_PKCS11_CKR_PIN_LOCKED = 1121
    case AWS_ERROR_PKCS11_CKR_SESSION_CLOSED = 1122
    case AWS_ERROR_PKCS11_CKR_SESSION_COUNT = 1123
    case AWS_ERROR_PKCS11_CKR_SESSION_HANDLE_INVALID = 1124
    case AWS_ERROR_PKCS11_CKR_SESSION_PARALLEL_NOT_SUPPORTED = 1125
    case AWS_ERROR_PKCS11_CKR_SESSION_READ_ONLY = 1126
    case AWS_ERROR_PKCS11_CKR_SESSION_EXISTS = 1127
    case AWS_ERROR_PKCS11_CKR_SESSION_READ_ONLY_EXISTS = 1128
    case AWS_ERROR_PKCS11_CKR_SESSION_READ_WRITE_SO_EXISTS = 1129
    case AWS_ERROR_PKCS11_CKR_SIGNATURE_INVALID = 1130
    case AWS_ERROR_PKCS11_CKR_SIGNATURE_LEN_RANGE = 1131
    case AWS_ERROR_PKCS11_CKR_TEMPLATE_INCOMPLETE = 1132
    case AWS_ERROR_PKCS11_CKR_TEMPLATE_INCONSISTENT = 1133
    case AWS_ERROR_PKCS11_CKR_TOKEN_NOT_PRESENT = 1134
    case AWS_ERROR_PKCS11_CKR_TOKEN_NOT_RECOGNIZED = 1135
    case AWS_ERROR_PKCS11_CKR_TOKEN_WRITE_PROTECTED = 1136
    case AWS_ERROR_PKCS11_CKR_UNWRAPPING_KEY_HANDLE_INVALID = 1137
    case AWS_ERROR_PKCS11_CKR_UNWRAPPING_KEY_SIZE_RANGE = 1138
    case AWS_ERROR_PKCS11_CKR_UNWRAPPING_KEY_TYPE_INCONSISTENT = 1139
    case AWS_ERROR_PKCS11_CKR_USER_ALREADY_LOGGED_IN = 1140
    case AWS_ERROR_PKCS11_CKR_USER_NOT_LOGGED_IN = 1141
    case AWS_ERROR_PKCS11_CKR_USER_PIN_NOT_INITIALIZED = 1142
    case AWS_ERROR_PKCS11_CKR_USER_TYPE_INVALID = 1143
    case AWS_ERROR_PKCS11_CKR_USER_ANOTHER_ALREADY_LOGGED_IN = 1144
    case AWS_ERROR_PKCS11_CKR_USER_TOO_MANY_TYPES = 1145
    case AWS_ERROR_PKCS11_CKR_WRAPPED_KEY_INVALID = 1146
    case AWS_ERROR_PKCS11_CKR_WRAPPED_KEY_LEN_RANGE = 1147
    case AWS_ERROR_PKCS11_CKR_WRAPPING_KEY_HANDLE_INVALID = 1148
    case AWS_ERROR_PKCS11_CKR_WRAPPING_KEY_SIZE_RANGE = 1149
    case AWS_ERROR_PKCS11_CKR_WRAPPING_KEY_TYPE_INCONSISTENT = 1150
    case AWS_ERROR_PKCS11_CKR_RANDOM_SEED_NOT_SUPPORTED = 1151
    case AWS_ERROR_PKCS11_CKR_RANDOM_NO_RNG = 1152
    case AWS_ERROR_PKCS11_CKR_DOMAIN_PARAMS_INVALID = 1153
    case AWS_ERROR_PKCS11_CKR_CURVE_NOT_SUPPORTED = 1154
    case AWS_ERROR_PKCS11_CKR_BUFFER_TOO_SMALL = 1155
    case AWS_ERROR_PKCS11_CKR_SAVED_STATE_INVALID = 1156
    case AWS_ERROR_PKCS11_CKR_INFORMATION_SENSITIVE = 1157
    case AWS_ERROR_PKCS11_CKR_STATE_UNSAVEABLE = 1158
    case AWS_ERROR_PKCS11_CKR_CRYPTOKI_NOT_INITIALIZED = 1159
    case AWS_ERROR_PKCS11_CKR_CRYPTOKI_ALREADY_INITIALIZED = 1160
    case AWS_ERROR_PKCS11_CKR_MUTEX_BAD = 1161
    case AWS_ERROR_PKCS11_CKR_MUTEX_NOT_LOCKED = 1162
    case AWS_ERROR_PKCS11_CKR_NEW_PIN_MODE = 1163
    case AWS_ERROR_PKCS11_CKR_NEXT_OTP = 1164
    case AWS_ERROR_PKCS11_CKR_EXCEEDED_MAX_ITERATIONS = 1165
    case AWS_ERROR_PKCS11_CKR_FIPS_SELF_TEST_FAILED = 1166
    case AWS_ERROR_PKCS11_CKR_LIBRARY_LOAD_FAILED = 1167
    case AWS_ERROR_PKCS11_CKR_PIN_TOO_WEAK = 1168
    case AWS_ERROR_PKCS11_CKR_PUBLIC_KEY_INVALID = 1169
    case AWS_ERROR_PKCS11_CKR_FUNCTION_REJECTED = 1170
    case AWS_ERROR_IO_PINNED_EVENT_LOOP_MISMATCH = 1171
    case AWS_ERROR_PKCS11_ENCODING_ERROR = 1172
    case AWS_IO_TLS_ERROR_DEFAULT_TRUST_STORE_NOT_FOUND = 1173

    /// AWS-C-HTTP
    case AWS_ERROR_HTTP_UNKNOWN = 2048
    case AWS_ERROR_HTTP_HEADER_NOT_FOUND = 2049
    case AWS_ERROR_HTTP_INVALID_HEADER_FIELD = 2050
    case AWS_ERROR_HTTP_INVALID_HEADER_NAME = 2051
    case AWS_ERROR_HTTP_INVALID_HEADER_VALUE = 2052
    case AWS_ERROR_HTTP_INVALID_METHOD = 2053
    case AWS_ERROR_HTTP_INVALID_PATH = 2054
    case AWS_ERROR_HTTP_INVALID_STATUS_CODE = 2055
    case AWS_ERROR_HTTP_MISSING_BODY_STREAM = 2056
    case AWS_ERROR_HTTP_INVALID_BODY_STREAM = 2057
    case AWS_ERROR_HTTP_CONNECTION_CLOSED = 2058
    case AWS_ERROR_HTTP_SWITCHED_PROTOCOLS = 2059
    case AWS_ERROR_HTTP_UNSUPPORTED_PROTOCOL = 2060
    case AWS_ERROR_HTTP_REACTION_REQUIRED = 2061
    case AWS_ERROR_HTTP_DATA_NOT_AVAILABLE = 2062
    case AWS_ERROR_HTTP_OUTGOING_STREAM_LENGTH_INCORRECT = 2063
    case AWS_ERROR_HTTP_CALLBACK_FAILURE = 2064
    case AWS_ERROR_HTTP_WEBSOCKET_UPGRADE_FAILURE = 2065
    case AWS_ERROR_HTTP_WEBSOCKET_CLOSE_FRAME_SENT = 2066
    case AWS_ERROR_HTTP_WEBSOCKET_IS_MIDCHANNEL_HANDLER = 2067
    case AWS_ERROR_HTTP_CONNECTION_MANAGER_INVALID_STATE_FOR_ACQUIRE = 2068
    case AWS_ERROR_HTTP_CONNECTION_MANAGER_VENDED_CONNECTION_UNDERFLOW = 2069
    case AWS_ERROR_HTTP_SERVER_CLOSED = 2070
    case AWS_ERROR_HTTP_PROXY_CONNECT_FAILED = 2071
    case AWS_ERROR_HTTP_CONNECTION_MANAGER_SHUTTING_DOWN = 2072
    case AWS_ERROR_HTTP_CHANNEL_THROUGHPUT_FAILURE = 2073
    case AWS_ERROR_HTTP_PROTOCOL_ERROR = 2074
    case AWS_ERROR_HTTP_STREAM_IDS_EXHAUSTED = 2075
    case AWS_ERROR_HTTP_GOAWAY_RECEIVED = 2076
    case AWS_ERROR_HTTP_RST_STREAM_RECEIVED = 2077
    case AWS_ERROR_HTTP_RST_STREAM_SENT = 2078
    case AWS_ERROR_HTTP_STREAM_NOT_ACTIVATED = 2079
    case AWS_ERROR_HTTP_STREAM_HAS_COMPLETED = 2080
    case AWS_ERROR_HTTP_PROXY_STRATEGY_NTLM_CHALLENGE_TOKEN_MISSING = 2081
    case AWS_ERROR_HTTP_PROXY_STRATEGY_TOKEN_RETRIEVAL_FAILURE = 2082
    case AWS_ERROR_HTTP_PROXY_CONNECT_FAILED_RETRYABLE = 2083
    case AWS_ERROR_HTTP_PROTOCOL_SWITCH_FAILURE = 2084
    case AWS_ERROR_HTTP_MAX_CONCURRENT_STREAMS_EXCEEDED = 2085
    case AWS_ERROR_HTTP_STREAM_MANAGER_SHUTTING_DOWN = 2086
    case AWS_ERROR_HTTP_STREAM_MANAGER_CONNECTION_ACQUIRE_FAILURE = 2087
    case AWS_ERROR_HTTP_STREAM_MANAGER_UNEXPECTED_HTTP_VERSION = 2088

    /// AWS-C-COMPRESSION
    case AWS_ERROR_COMPRESSION_UNKNOWN_SYMBOL = 3072

    /// AWS-C-EVENTSTREAM

    /// AWS-C-AUTH
    case AWS_AUTH_SIGNING_UNSUPPORTED_ALGORITHM = 6144
    case AWS_AUTH_SIGNING_MISMATCHED_CONFIGURATION = 6145
    case AWS_AUTH_SIGNING_NO_CREDENTIALS = 6146
    case AWS_AUTH_SIGNING_ILLEGAL_REQUEST_QUERY_PARAM = 6147
    case AWS_AUTH_SIGNING_ILLEGAL_REQUEST_HEADER = 6148
    case AWS_AUTH_SIGNING_INVALID_CONFIGURATION = 6149
    case AWS_AUTH_CREDENTIALS_PROVIDER_INVALID_ENVIRONMENT = 6150
    case AWS_AUTH_CREDENTIALS_PROVIDER_INVALID_DELEGATE = 6151
    case AWS_AUTH_CREDENTIALS_PROVIDER_PROFILE_SOURCE_FAILURE = 6152
    case AWS_AUTH_CREDENTIALS_PROVIDER_IMDS_SOURCE_FAILURE = 6153
    case AWS_AUTH_CREDENTIALS_PROVIDER_STS_SOURCE_FAILURE = 6154
    case AWS_AUTH_CREDENTIALS_PROVIDER_HTTP_STATUS_FAILURE = 6155
    case AWS_AUTH_PROVIDER_PARSER_UNEXPECTED_RESPONSE = 6156
    case AWS_AUTH_CREDENTIALS_PROVIDER_ECS_SOURCE_FAILURE = 6157
    case AWS_AUTH_CREDENTIALS_PROVIDER_X509_SOURCE_FAILURE = 6158
    case AWS_AUTH_CREDENTIALS_PROVIDER_PROCESS_SOURCE_FAILURE = 6159
    case AWS_AUTH_CREDENTIALS_PROVIDER_STS_WEB_IDENTITY_SOURCE_FAILURE = 6160
    case AWS_AUTH_SIGNING_UNSUPPORTED_SIGNATURE_TYPE = 6161
    case AWS_AUTH_SIGNING_MISSING_PREVIOUS_SIGNATURE = 6162
    case AWS_AUTH_SIGNING_INVALID_CREDENTIALS = 6163
    case AWS_AUTH_CANONICAL_REQUEST_MISMATCH = 6164
    case AWS_AUTH_SIGV4A_SIGNATURE_VALIDATION_FAILURE = 6165
    case AWS_AUTH_CREDENTIALS_PROVIDER_COGNITO_SOURCE_FAILURE = 6166

    /// AWS-C-CAL
    case AWS_ERROR_CAL_SIGNATURE_VALIDATION_FAILED = 7168
    case AWS_ERROR_CAL_MISSING_REQUIRED_KEY_COMPONENT = 7169
    case AWS_ERROR_CAL_INVALID_KEY_LENGTH_FOR_ALGORITHM = 7170
    case AWS_ERROR_CAL_UNKNOWN_OBJECT_IDENTIFIER = 7171
    case AWS_ERROR_CAL_MALFORMED_ASN1_ENCOUNTERED = 7172
    case AWS_ERROR_CAL_MISMATCHED_DER_TYPE = 7173
    case AWS_ERROR_CAL_UNSUPPORTED_ALGORITHM = 7174

    /// AWS-C-SDKUTILS
    case AWS_ERROR_SDKUTILS_GENERAL = 15360
    case AWS_ERROR_SDKUTILS_PARSE_FATAL = 15361
    case AWS_ERROR_SDKUTILS_PARSE_RECOVERABLE = 15362
}
