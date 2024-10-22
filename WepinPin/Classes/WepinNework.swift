

import Foundation

class WepinNework : NetworkManager {
    private var accessToken: String? = nil
    private var refreshToken: String? = nil
    
    init(appKey:String, sdkVersion:String) {
        super.init(appKey: appKey)
        let headers: [String: String] = [
            "Content-Type": "application/json",
            "X-API-KEY": appKey,
            "X-API-DOMAIN" : Bundle.main.bundleIdentifier ?? "",
            "X-SDK-VERSION": sdkVersion,
            "X-SDK-TYPE": "ios-pin"
        ]
        setCommonHeader(header: headers)
    }
    
    func setAuthToken(accessToken:String, refreshToken:String){
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        setAuthHeader(token: accessToken)
    }
    
    func clearAuthToken(){
        self.accessToken = nil
        self.refreshToken = nil
        clearAuthHeader()
    }
    
    public func getAppInfo() async throws -> Any {
        return try await withCheckedThrowingContinuation { continuation in
            getRequest(endpoint: "app/info") { result in
                switch result {
                case .success(let jsonResponse):
                    continuation.resume(returning: jsonResponse)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    
    public func getAccessToken(userId:String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            getRequest(endpoint: "user/access-token?userId=\(userId)&refresh_token=\(self.refreshToken!)", responseType: WepinGetAccessTokenResponse.self) { result in
                switch result {
                case .success(let jsonResponse):
                    self.setAuthToken(accessToken: jsonResponse.token, refreshToken: self.refreshToken!)
                    continuation.resume(returning: jsonResponse.token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

enum WepinNetworkError: Error {
    case resultFailed
    case parsingFailed
}
