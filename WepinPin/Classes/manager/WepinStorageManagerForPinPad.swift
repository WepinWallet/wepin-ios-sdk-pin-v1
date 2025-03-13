//
//  WepinStoragaeManager.swift
//  Pods
//
//  Created by musicgi on 3/10/25.
//

import Security


class WepinStorageManagerForPinPad {

    private let service = "wepin_key_chain_v1"

    private func formatKey(appId: String, key: String?) -> String {
        return "\(appId)_\(key ?? "")"
    }

    func write(appId: String, key: String?, data: Data?) {

        let formattedKey = formatKey(appId: appId, key: key)
        //let data = (data as? String)?.data(using: .utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: formattedKey,
            kSecValueData as String: data ?? Data()
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Failed to write data to keychain")
        }
    }

    func read(appId: String, key: String?) -> Data? {
        let formattedKey = formatKey(appId: appId, key: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: formattedKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return data // String(data: data, encoding: .utf8)
        }
        return nil
    }

    func delete(appId: String, key: String?) {
        let formattedKey = formatKey(appId: appId, key: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: formattedKey
        ]

        SecItemDelete(query as CFDictionary)
    }

    func deleteAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        SecItemDelete(query as CFDictionary)
    }

    func readAll(appId: String) -> [String: Data?] {
        var result = [String: Data?]()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var items: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &items)
        if status == errSecSuccess, let items = items as? [[String: Any]] {
            for item in items {
                if let account = item[kSecAttrAccount as String] as? String,
                   let data = item[kSecValueData as String] as? Data,
                   account.hasPrefix(appId) {
                    let key = account.replacingOccurrences(of: "\(appId)_", with: "")
                    result[key] = data //String(data: data, encoding: .utf8)
                }
            }
        }

        return result
    }

    func writeAll(appId: String, data: [String: Data?]) {
        for (key, value) in data {
            write(appId: appId, key: key, data: value)
        }
    }
}
