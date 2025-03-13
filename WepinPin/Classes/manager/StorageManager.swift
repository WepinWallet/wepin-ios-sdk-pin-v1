
import Foundation
import Security

class StorageManager {
    static let shared = StorageManager()
    
    private var appId: String = ""
    private let prevSevicePrefix: String = "wepin" + (Bundle.main.bundleIdentifier ?? "")

    private let wepinStorageManager = WepinStorageManagerForPinPad()
    
    func initManager(appId: String) {
        self.appId = appId
        migrateOldStorage()
    }
    
    //Migration Logic
    private func migrateOldStorage() {
        guard getStorage(key: "migration") as? String != "true" else { return }

        prevStorageReadAll()
        setStorage(key: "migration", data: "true")
        let data = getAllStorage()
        prevDeleteAll()
    }

    private func prevStorageReadAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: prevSevicePrefix + appId,
            kSecReturnAttributes as String: kCFBooleanTrue!,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var items: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &items) == errSecSuccess,
              let itemArray = items as? [[String: Any]] else { return  }

        itemArray.forEach { item in
            if let key = item[kSecAttrAccount as String] as? String,
               let data = item[kSecValueData as String] as? Data {
                setStorage(key: key, data: data)
            }
        }
    }
    
    private func prevDeleteAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: prevSevicePrefix  + appId
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    private func encodeData<T: Codable>(value: T) -> Data? {
        // String 타입인 경우
        if let stringValue = value as? String {
            return stringValue.data(using: .utf8)
        }
        
        // Data 타입인 경우
        if let dataValue = value as? Data {
            return dataValue
        }
        
        // Dictionary 타입인 경우 (JSON으로 변환)
        if let jsonValue = value as? [String: Any] {
            return try? JSONSerialization.data(withJSONObject: jsonValue, options: [])
        }
        
        // Int 타입인 경우 (바이트 배열로 변환)
        if let intValue = value as? Int {
            var intData = intValue
            return Data(bytes: &intData, count: MemoryLayout.size(ofValue: intData))
        }
        
        // Codable 타입인 경우 (JSON으로 변환)
        do {
           return try JSONEncoder().encode(value)
        } catch {
            return nil
        }
        
        // 변환할 수 없는 경우 nil 반환
//        return nil
    }

    func decodeData(data: Data) -> Any? {
        
        // Data를 JSON으로 변환 시도
        if let jsonValue = try? JSONSerialization.jsonObject(with: data, options: []),
           let dictionaryValue = jsonValue as? [String: Any] {
            return dictionaryValue
        }
        
        // Data를 Int로 변환 시도
        if data.count == MemoryLayout<Int>.size {
            var intValue: Int = 0
            _ = withUnsafeMutableBytes(of: &intValue) { data.copyBytes(to: $0) }
            return intValue
        }
        
        // Data를 String으로 변환 시도
        if let stringValue = String(data: data, encoding: .utf8) {
            return stringValue
        }
        
        // 변환할 수 없는 경우 nil 반환
        return nil
    }
    func setStorage<T: Codable&Any>(key: String, data: T) {
        let keychainData = encodeData(value: data)
        wepinStorageManager.write(appId: appId, key: key, data: keychainData!)
    }

    func getStorage<T: Decodable>(key: String, type: T.Type) -> T? {
        guard let data = wepinStorageManager.read(appId: appId, key: key) else {
//            print("Error fetching data from keychain: \(status)")
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: data)
    }
    func getStorage(key: String) -> Any? {
        guard  let data = wepinStorageManager.read(appId: appId, key: key) else {
                    print("Error fetching data from keychain: data")
//            print("Error retrieving data from keychain: \(status)")
            return nil
        }

        return decodeData(data: data)
//        return try? JSONSerialization.jsonObject(with: data, options: [])
    }

    func deleteStorage(key: String) {
        wepinStorageManager.delete(appId: appId, key: key)
    }

    func getAllStorage() -> [String: Any] {
        return wepinStorageManager.readAll(appId: appId).reduce(into: [:]) { result, item in
            if let data = item.value {
                result[item.key] = decodeData(data: data)
            }
        }
    }

    func setAllStorage(data: [String: Codable]) {
        for (key, value) in data {
            setStorage(key: key, data: value)
        }
    }
    

    func deleteAllStorage() {
        wepinStorageManager.deleteAll()
        setStorage(key: "migration", data: "true")
    }
}

struct StorageDataType {
    struct FirebaseWepin : Codable{
        let idToken: String
        let refreshToken: String
        let provider: String
    }

    struct WepinToken : Codable{
        let accessToken: String
        let refreshToken: String
    }

    struct UserStatus : Codable{
        let loginStatus: String
        let pinRequired: Bool
    }

    struct UserInfo : Codable{
        let status: String
        let userInfo: UserInfoDetails
        let walletId: String?
    }
    
    struct UserInfoDetails : Codable {
        let userId: String
        let email: String
        let provider: String
        let use2FA: Bool
    }
}
