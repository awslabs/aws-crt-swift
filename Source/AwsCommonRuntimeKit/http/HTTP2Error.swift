//
// Created by Khan, Waqar Ahmed on 12/26/22.
//

import Foundation

public enum HTTP2Error: UInt32 {
    case PROTOCOL_ERROR = 1
    case INTERNAL_ERROR = 2
    case FLOW_CONTROL_ERROR = 3
    case SETTINGS_TIMEOUT = 4
    case STREAM_CLOSED = 5
    case FRAME_SIZE_ERROR = 6
    case REFUSED_STREAM = 7
    case CANCEL = 8
    case COMPRESSION_ERROR = 9
    case CONNECT_ERROR = 10
    case ENHANCE_YOUR_CALM = 11
    case INADEQUATE_SECURITY = 12
    case HTTP_1_1_REQUIRED = 13
}
