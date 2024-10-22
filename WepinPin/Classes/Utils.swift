
import Foundation

// 사용 예시
func isFirstEmailUser(errorString: String) -> Bool {
    do {
       // JSON 문자열 추출
       let data = errorString.data(using: .utf8)!
       let jsonObject = try JSONSerialization.jsonObject(with: data, options:  [.allowFragments])
       guard let dictionary = jsonObject as? [String: Any] else {
           return false
       }

       // 필요한 필드 값 추출
       guard let status = dictionary["status"] as? Int,
             let message = dictionary["message"] as? String else {
           return false
       }

       // 조건 검사
       let isStatus400 = (status == 400)
       let isMessageContainsNotExist = message.contains("not exist")

       // 결과 출력
       return isStatus400 && isMessageContainsNotExist
   } catch {
//       print("Error parsing JSON: \(error.localizedDescription)")
       return false
   }
}

// JSON 디코딩 함수
func decodeJSONToDictionary(jsonData: Data) -> [String: Codable]? {
    do {
        if let jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Codable] {
            return jsonDictionary
        }
    } catch {
//        print("JSON 디코딩 에러: \(error.localizedDescription)")
    }
    return nil
}

// URL 인코딩 함수
func customURLEncode(_ string: String) -> String {
    // 인코딩할 캐릭터셋을 정의
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: ":/")
    return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
}


func convertToAnyCodable(_ value: Any) -> AnyCodable {
    if let dict = value as? [String: Any] {
        return AnyCodable(convertToAnyCodableDictionary(dict))
    } else if let array = value as? [Any] {
        return AnyCodable(array.map { convertToAnyCodable($0) })
    } else {
        return AnyCodable(value)
    }
}

func convertToAnyCodableDictionary(_ dictionary: [String: Any]) -> [String: AnyCodable] {
    var result: [String: AnyCodable] = [:]
    for (key, value) in dictionary {
        result[key] = convertToAnyCodable(value)
    }
    return result
}

func convertJsonToLocalStorageData(_ jsonString: String) -> Any? {
    // JSON 문자열을 Data로 변환
    guard let jsonData = jsonString.data(using: .utf8) else {
        print("Failed to convert JSON string to Data")
        return nil
    }
    
    // JSON 데이터 파싱
    do {
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
        return jsonObject
    } catch {
        print("Error parsing JSON data: \(error.localizedDescription)")
        return nil
    }
}

