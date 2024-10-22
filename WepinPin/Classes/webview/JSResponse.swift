import Foundation

// JSResponse 구조체
struct JSResponse: Codable {
    let header: JSResponseHeader
    var body: JSResponseBody

    struct JSResponseHeader: Codable {
        let id: String
        let response_from: String
        let response_to: String
    }

    struct JSResponseBody: Codable {
        let command: String
        var state: String
        var data: AnyCodable? = nil
    }

    // JSResponse의 Builder 패턴
    class Builder {
        private var response: JSResponse

        init(id: String, requestFrom: String, command: String, state: String) {
            self.response = JSResponse(
                header: JSResponseHeader(id: id, response_from: "native", response_to: requestFrom),
                body: JSResponseBody(command: command, state: state)
            )
        }

        // ReadyToWidgetBodyData 구조체 정의
        struct ReadyToWidgetBodyData: Codable {
            let appKey: String
            let appId: String
            let domain: String
            let platform: Int
            let type: String
            let version: String
            let localData: [String: AnyCodable]
            let attributes: WepinPinAttributes?

            func toDictionary() -> [String: AnyCodable] {
                var dict: [String: AnyCodable] = [
                    "appKey": AnyCodable(appKey),
                    "appId": AnyCodable(appId),
                    "domain": AnyCodable(domain),
                    "platform": AnyCodable(platform),
                    "type": AnyCodable(type),
                    "version": AnyCodable(version),
                    "localDate": AnyCodable(localData)
                ]
                
                // attributes가 nil이 아닐 때만 추가
                if let attributes = attributes {
                    dict["attributes"] = AnyCodable(attributes.toDictionary())
                }
                return dict
            }
        }
        
        func setBodyData(parameter: Any) -> Builder {
            if let dict = parameter as? [String: AnyCodable] {
                // parameter가 딕셔너리 형태일 때 처리
                self.response.body.data = AnyCodable(dict)
            } else if let singleValue = parameter as? AnyCodable {
                // parameter가 단일 값일 때 처리
                self.response.body.data = singleValue
            } else {
                // 예상하지 못한 데이터 타입일 경우 처리 (옵션)
                self.response.body.data = AnyCodable("Invalid parameter type")
            }
            
            return self
        }


        func setErrorBodyData(errMsg: String) -> Builder {
            self.response.body.data = AnyCodable(errMsg)
            return self
        }

        func build() -> JSResponse {
            return self.response
        }
    }

    // JSON 변환을 위한 함수
    func toJsonString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let jsonData = try encoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("##### [Response] \(jsonString)")
                return jsonString
            }
        } catch {
            print("Error converting to JSON: \(error.localizedDescription)")
        }
        return "Error converting to JSON"
    }
}

extension WepinPinAttributes {
    func toDictionary() -> [String: AnyCodable] {
        return [
            "defaultLanguage": AnyCodable(defaultLanguage ?? "en")
        ]
    }
}

