struct Command {
    // Commands for JS processor
    static let CMD_READY_TO_WIDGET = "ready_to_widget"
    static let CMD_GET_SDK_REQUEST = "get_sdk_request"
    static let CMD_CLOSE_WEPIN_WIDGET = "close_wepin_widget"
    static let CMD_SET_LOCAL_STORAGE = "set_local_storage"
    
    // Commands for get_sdk_request
    static let CMD_SUB_PIN_REGISTER = "pin_register"  // only for creating wallet
    static let CMD_SUB_PIN_AUTH = "pin_auth"
    static let CMD_SUB_PIN_CHANGE = "pin_change"
    static let CMD_SUB_PIN_OTP = "pin_otp"
}

struct State {
    // Commands for JS processor
    static let STATE_SUCCESS = "SUCCESS"
    static let STATE_ERROR = "ERROR"
}
