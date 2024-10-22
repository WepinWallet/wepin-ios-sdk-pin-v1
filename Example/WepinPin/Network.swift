import Foundation

// MARK: - Models

import WepinPin

public struct RegisterRequest: Codable {
    public let userId: String
    public let loginStatus: String
    public let walletId: String?
    public let UVD: EncUVD?
    public let hint: EncPinHint?
}
struct RegisterResponse: Codable {
    let success: Bool
    let walletId: String
}

struct OtpCode: Codable {
    let code: String
    let recovery: Bool
}

struct ChangePinRequest: Codable {
    let userId: String
    let walletId: String
    let UVD: EncUVD  // EncUVD가 Codable을 준수해야 함
    let newUVD: EncUVD  // EncUVD가 Codable을 준수해야 함
    let hint: EncPinHint  // EncPinHint가 Codable을 준수해야 함
    let otpCode: OtpCode?
}

struct ChangePinResponse: Codable {
    let status: Bool
}

// Custom Codable to handle [String: Any] in txData
struct SignRequest: Codable {
    let type: String
    let userId: String
    let walletId: String
    let accountId: String
    let contract: String?
    let tokenId: String?
    let isNft: String?
    let pin: EncUVD  // EncUVD가 Codable을 준수해야 함
    let otpCode: OtpCode?
    let txData: [String: String]  // [String: Any] 대신 [String: String] 사용 가능
}

//struct SignResponse: Codable {
//    let signatureResult: String?  // 이 필드는 커스텀 처리 필요할 수 있음
//    let transaction: [String: String]  // [String: Any] 대신 [String: String] 사용 가능
//    let broadcastData: String?
//    let txId: String?
//}
struct SignResponse: Codable {
    let signatureResult: String
    let transaction: Transaction
}

struct Transaction: Codable {
    let data: String
    let coinId: Int  // 여기서 String에서 Int로 변경
    let address: String
}

struct GetAccountListRequest: Codable {
    let walletId: String
    let userId: String
    let localeId: String
}

struct GetAccountListResponse: Codable {
    let walletId: String
    let accounts: [IAppAccount]
    let aa_accounts: [IAppAccount]?
}

struct IAppAccount: Codable {
    let accountId: String
    let address: String
    let eoaAddress: String?
    let addressPath: String
    let coinId: Int?
    let contract: String?
    let symbol: String
    let label: String
    let name: String
    let network: String
    let balance: String
    let decimals: Int
    let iconUrl: String
    let ids: String?
    let accountTokenId: String?
    let cmkId: Int?
    let isAA: Bool?
}

// MARK: - Network Class

class Network {
    private let appKey: String
    private let baseUrl: String
    private var accessToken: String?
    private var refreshToken: String?
    
    init(appKey: String) {
        self.appKey = appKey
        self.baseUrl = Network.getUrl(appKey: appKey)
    }
    
    static func getUrl(appKey: String) -> String {
        if appKey.hasPrefix("ak_dev") {
            return "https://dev-sdk.wepin.io/v1/"
        } else if appKey.hasPrefix("ak_test") {
            return "https://stage-sdk.wepin.io/v1/"
        } else if appKey.hasPrefix("ak_live") {
            return "https://sdk.wepin.io/v1/"
        } else {
            fatalError("Invalid app key")
        }
    }
    
    func setAuthToken(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    func setHeaders() -> [String: String] {
        var headers: [String: String] = [
            "Content-Type": "application/json",
            "X-API-KEY": appKey,
            "X-API-DOMAIN": Bundle.main.bundleIdentifier ?? "",
            "X-SDK-TYPE": "ios-rest-api",
            "X-SDK-VERSION": PodVersion
        ]
        
        if let token = accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        return headers
    }
    
    func httpRequest<T: Codable>(url: String, method: String, headers: [String: String], body: Data? = nil, completion: @escaping (Result<T, Error>) -> Void) {
        guard let requestUrl = URL(string: url) else { return }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = method
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        if method == "POST" || method == "PATCH", let bodyData = body {
            request.httpBody = bodyData
            //print("Request Body: \(String(data: bodyData, encoding: .utf8) ?? "nil")")
        }
        
//        print("Request URL: \(requestUrl)")
//        print("Request Method: \(method)")
//        print("Request Headers: \(headers)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let httpResponse = response as? HTTPURLResponse else { return }
            
//            print("Response Status Code: \(httpResponse.statusCode)")
//            print("Response Headers: \(httpResponse.allHeaderFields)")
//            print("Response Body: \(data)")
            
            if (200...299).contains(httpResponse.statusCode) {
                do {
                    // 응답 데이터를 문자열로 변환하여 출력
                     if let jsonString = String(data: data, encoding: .utf8) {
                         print("Response JSON String: \(jsonString)")
                     }
                     
                     // 응답 데이터를 디코딩하여 결과로 반환
                     let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                     completion(.success(decodedResponse))
                } catch {
                    print("Failed to decode response: \(error)")
                    completion(.failure(error))
                }
            } else {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                let wepinError = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorString])
                print("Error Response: \(errorString)")
                completion(.failure(wepinError))
            }
        }
        
        task.resume()
    }
    
    func register(params: RegisterRequest, completion: @escaping (Result<RegisterResponse, Error>) -> Void) {
        let url = "\(baseUrl)app/register"
        let jsonData = try? JSONEncoder().encode(params)
        httpRequest(url: url, method: "POST", headers: setHeaders(), body: jsonData, completion: completion)
    }
    
    func changePin(params: ChangePinRequest, completion: @escaping (Result<ChangePinResponse, Error>) -> Void) {
        let url = "\(baseUrl)wallet/pin/change"
        let jsonData = try? JSONEncoder().encode(params)
        httpRequest(url: url, method: "PATCH", headers: setHeaders(), body: jsonData, completion: completion)
    }
    
    func sign(params: SignRequest) async -> Result<SignResponse, Error> {
        let url = "\(baseUrl)tx/sign"
        let jsonData = try? JSONEncoder().encode(params)
        return await withCheckedContinuation { continuation in
            httpRequest(url: url, method: "POST", headers: setHeaders(), body: jsonData) { result in
                continuation.resume(returning: result)
            }
        }
    }
    func getAppAccountList(params: GetAccountListRequest, completion: @escaping (Result<GetAccountListResponse, Error>) -> Void) {
        let url = "\(baseUrl)account?walletId=\(params.walletId)&userId=\(params.userId)&localeId=\(params.localeId)"
        httpRequest(url: url, method: "GET", headers: setHeaders(), completion: completion)
    }
}

