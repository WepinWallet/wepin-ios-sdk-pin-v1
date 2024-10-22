
import Foundation

class NetworkManager {
    var baseURL: String
    
    init(appKey: String) {
        self.baseURL = NetworkManager.getSdkUrl(appKey: appKey) ?? ""
    }
    
    private static func getSdkUrl(appKey: String) -> String? {
        var urlString:String? = nil
        
        if (appKey.hasPrefix("ak_live_")) {
            urlString = "https://sdk.wepin.io/v1/"
        }else if(appKey.hasPrefix("ak_test_")) {
            urlString = "https://stage-sdk.wepin.io/v1/"
        }else if(appKey.hasPrefix("ak_dev_")) {
            urlString = "https://dev-sdk.wepin.io/v1/"
        }
        
        return urlString
    }
    
    private var commonHeaders: [String: String] = [
        "Content-Type": "application/json"
    ]
    
    func setCommonHeader(header: [String: String] ) {
        for(key, value) in header {
            commonHeaders[key] = value
        }
    }
    
    func setAuthHeader(token: String) {
        commonHeaders["Authorization"] = "Bearer " + token
    }
    
    func clearAuthHeader() {
        commonHeaders.removeValue(forKey: "Authorization")
    }
    
    func isErrorResponse (response: Data) -> String? {
        if let status = (try? JSONSerialization.jsonObject(with: response, options: []) as? [String: Any])?["status"] as? Int {
            if status  >= 300 || status < 200 {
                let updatedJsonString = String(data: response, encoding: .utf8)
                return updatedJsonString
            }
        }
        return nil
    }
    
    private func createRequest(endpoint: String, method: String, parameters: Data? = nil) -> URLRequest? {
        let urlString = baseURL + endpoint
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // 공통 헤더 추가
        for (key, value) in commonHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 파라미터가 있을 경우 HTTP Body 설정
        if let parameters = parameters {
            request.httpBody = parameters
        }
        
        return request
    }
    
    private func checkError(data: Data, response: URLResponse?) throws {
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse!.statusCode
        if (200...299).contains(statusCode) {
        } else {
            if let errorMessage = self.isErrorResponse(response: data) {
                throw NetworkError.faiedResponse(message: errorMessage)
            }else {
                let updatedJsonString = String(data: data, encoding: .utf8)
                throw NetworkError.faiedResponse(message: updatedJsonString ?? "statusCode: \(statusCode)")
            }
        }
    }
    
    func getRequest(endpoint: String, completion: @escaping (Result<Any, Error>) -> Void) {
        guard let request = createRequest(endpoint: endpoint, method: "GET") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            do {
                try self.checkError(data: data, response: response)
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                completion(.success(jsonResponse))
            } catch {
               completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func getRequest<T:Codable>(endpoint: String, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        guard let request = createRequest(endpoint: endpoint, method: "GET") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }

            do {
                try self.checkError(data: data, response: response)
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
               } else {
                   completion(.failure(WepinNetworkError.parsingFailed))
                   return
               }
               let decodedResponse = try JSONDecoder().decode(responseType, from: data)
               completion(.success(decodedResponse))
            } catch {
               completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func getStringRequest(endpoint: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let request = createRequest(endpoint: endpoint, method: "GET") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            do {
                try self.checkError(data: data, response: response)
            } catch{
                completion(.failure(error))
            }
            guard let stringData = String(data: data, encoding: .utf8) else {
                completion(.failure(NetworkError.parsingError))
                return
            }
            completion(.success(stringData))
        }
        
        task.resume()
    }
    
    func postRequest<T: Codable>(endpoint: String, responseType: T.Type,parameters: Data?, completion: @escaping (Result<T, Error>) -> Void) {
        guard let request = createRequest(endpoint: endpoint, method: "POST", parameters: parameters) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            do {
                try self.checkError(data: data, response: response)
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
               } else {
//                   print("JSON data is not a dictionary")
               }
               let decodedResponse = try JSONDecoder().decode(responseType, from: data)
               completion(.success(decodedResponse))
            } catch {
               completion(.failure(error))
            }

        }
        
        task.resume()
    }
    
    func patchRequest<T: Codable>(endpoint: String, responseType: T.Type, parameters: Data?, completion: @escaping (Result<T, Error>) -> Void) {
        guard let request = createRequest(endpoint: endpoint, method: "PATCH", parameters: parameters) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            do {
                try self.checkError(data: data, response: response)
                let decodedResponse = try JSONDecoder().decode(responseType, from: data)
               completion(.success(decodedResponse))
           } catch {
               completion(.failure(error))
           }

            
        }
        
        task.resume()
    }
}

// Error 정의
enum NetworkError: Error {
    case invalidURL
    case noData
    case parsingError
    case faiedResponse(message: String)
}
