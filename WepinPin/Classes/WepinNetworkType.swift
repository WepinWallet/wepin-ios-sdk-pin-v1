
import Foundation

// UserState 열거형
enum WepinUserState: Int, Codable {
    case active = 1
    case deleted = 2

    static func fromState(_ state: Int) -> WepinUserState? {
        return WepinUserState(rawValue: state)
    }
}

struct WepinGetAccessTokenResponse : Codable{
    let token: String
}

// OAuthTokenRequest 구조체
struct WepinOAuthTokenRequest: Codable {
    let code: String
    let clientId: String
    let redirectUri: String
    let state: String?
    let codeVerifier: String?
    
    init(code: String, clientId: String, redirectUri: String, state: String?=nil, codeVerifier: String?=nil) {
        self.code = code
        self.state = state
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.codeVerifier = codeVerifier
    }
}

// OAuthTokenResponse 구조체
struct WepinOAuthTokenResponse: Codable {
    let id_token: String?
    let access_token: String
    let token_type: String
    let expires_in: ExpiresIn?
    let refresh_token: String?
    let scope: String?
    
    enum ExpiresIn: Codable {
            case int(Int)
            case string(String)
            
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let value = try? container.decode(Int.self) {
                    self = .int(value)
                } else if let value = try? container.decode(String.self) {
                    self = .string(value)
                } else {
                    throw DecodingError.typeMismatch(ExpiresIn.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Int or String for expires_in"))
                }
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .int(let value):
                    try container.encode(value)
                case .string(let value):
                    try container.encode(value)
                }
            }
        }
}

// VerifyRequest 구조체
struct WepinVerifyRequest: Codable {
    let type: String
    let email: String
    let localeId: Int?
}

// VerifyResponse 구조체
struct WepinVerifyResponse: Codable {
    let result: Bool
    let oobReset: String?
    let oobVerify: String?
}

// PasswordStateResponse 구조체
struct WepinPasswordStateResponse: Codable {
    var isPasswordResetRequired: Bool
}

// PasswordStateRequest 구조체
struct WepinPasswordStateRequest: Codable {
    var isPasswordResetRequired: Bool
}

// CheckEmailExistResponse 구조체
struct WepinCheckEmailExistResponse: Codable {
    let isEmailExist: Bool
    let isEmailverified: Bool
    let providerIds: [String]
}

// LoginOauthAccessTokenRequest 구조체
public struct WepinLoginOauthAccessTokenRequest: Codable {
    let provider: String
    let accessToken: String
    let sign: String
    public init(provider: String, accessToken: String, sign: String) {
        self.provider = provider
        self.accessToken = accessToken
        self.sign = sign
    }
}


    struct WepinNetworEmptyType: Codable {
        
    }
    
  
