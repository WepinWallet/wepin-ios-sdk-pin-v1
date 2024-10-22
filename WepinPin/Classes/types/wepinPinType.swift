import Foundation

// EncUVD 구조체
public struct EncUVD: Codable {
    public let seqNum: Int?
    public let b64SKey: String
    public let b64Data: String

    public static func fromJson(_ json: [String: Any]) throws -> EncUVD {
        guard let b64SKey = json["b64SKey"] as? String,
              let b64Data = json["b64Data"] as? String else {
            throw NSError(domain: "Invalid EncUVD data", code: 0)
        }
        let seqNum = json["seqNum"] as? Int
        return EncUVD(seqNum: seqNum, b64SKey: b64SKey, b64Data: b64Data)
    }

    public func toJson() -> [String: Any] {
        return [
            "seqNum": seqNum as Any,
            "b64SKey": b64SKey,
            "b64Data": b64Data
        ]
    }
}

// EncPinHint 구조체
public struct EncPinHint: Codable {
    public let version: Int
    public let length: String
    public let data: String

    public static func fromJson(_ json: [String: Any]) throws -> EncPinHint {
        guard let version = (json["version"] as? NSNumber)?.intValue else {
            throw NSError(domain: "Invalid version", code: 0)
        }
        guard let length = json["length"] as? String else {
            throw NSError(domain: "Invalid length", code: 0)
        }
        guard let data = json["data"] as? String else {
            throw NSError(domain: "Invalid data", code: 0)
        }
        
        return EncPinHint(version: version, length: length, data: data)
    }

    public func toJson() -> [String: Any] {
        return [
            "version": version,
            "length": length,
            "data": data
        ]
    }
}

// ChangePinBlock 구조체
public struct ChangePinBlock: Codable {
    public let uvd: EncUVD
    public let newUVD: EncUVD
    public let hint: EncPinHint
    public let otp: String?

    public static func fromJson(_ json: [String: Any]) throws -> ChangePinBlock {
        guard let uvdJson = json["UVD"] as? [String: Any],
              let newUVDJson = json["newUVD"] as? [String: Any],
              let hintJson = json["hint"] as? [String: Any] else {
            throw NSError(domain: "Invalid JSON structure", code: 0)
        }
        
        let uvd = try EncUVD.fromJson(uvdJson)
        let newUVD = try EncUVD.fromJson(newUVDJson)
        let hint = try EncPinHint.fromJson(hintJson)
        let otp = json["otp"] as? String

        return ChangePinBlock(uvd: uvd, newUVD: newUVD, hint: hint, otp: otp)
    }

    public func toJson() -> [String: Any] {
        return [
            "UVD": uvd.toJson(),
            "newUVD": newUVD.toJson(),
            "hint": hint.toJson(),
            "otp": otp as Any
        ]
    }
}

// RegistrationPinBlock 구조체
public struct RegistrationPinBlock: Codable {
    public let uvd: EncUVD
    public let hint: EncPinHint

    public static func fromJson(_ json: [String: Any]) throws -> RegistrationPinBlock {
        guard let uvdJson = json["UVD"] as? [String: Any],
              let hintJson = json["hint"] as? [String: Any] else {
            throw NSError(domain: "Invalid JSON structure", code: 0)
        }

        let uvd = try EncUVD.fromJson(uvdJson)
        let hint = try EncPinHint.fromJson(hintJson)

        return RegistrationPinBlock(uvd: uvd, hint: hint)
    }

    public func toJson() -> [String: Any] {
        return [
            "UVD": uvd.toJson(),
            "hint": hint.toJson()
        ]
    }
}

// AuthOTP 구조체
public struct AuthOTP: Codable {
    public let code: String

    public static func fromJson(_ json: [String: Any]) throws -> AuthOTP {
        guard let code = json["code"] as? String else {
            throw NSError(domain: "Invalid code", code: 0)
        }
        return AuthOTP(code: code)
    }

    public func toJson() -> [String: Any] {
        return [
            "code": code
        ]
    }
}

// AuthPinBlock 구조체
public struct AuthPinBlock: Codable {
    public let uvdList: [EncUVD]
    public let otp: String?

    public static func fromJson(_ json: [String: Any]) throws -> AuthPinBlock {
        guard let uvdListJson = json["UVDs"] as? [[String: Any]] else {
            throw NSError(domain: "Invalid UVDs", code: 0)
        }

        let uvdList = try uvdListJson.map { try EncUVD.fromJson($0) }
        let otp = json["otp"] as? String

        return AuthPinBlock(uvdList: uvdList, otp: otp)
    }

    public func toJson() -> [String: Any] {
        return [
            "UVDs": uvdList.map { $0.toJson() },
            "otp": otp as Any
        ]
    }
}

