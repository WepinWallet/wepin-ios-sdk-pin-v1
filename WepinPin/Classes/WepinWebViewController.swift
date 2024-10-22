import UIKit
import WebKit
import SafariServices

public class WepinWebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    private var webView: WKWebView?
    private var appKey: String?
    private var appId: String?
    private var webViewUrl: String?
    private var attributes: WepinPinAttributes? = nil
    internal var currentWepinRequest: [String: Any]? = nil // 웹뷰의 get_sdk_request 요청에 대한 응답 Request
    var currentResponseDeferred: ((String) -> Void)?

    
    init(appKey: String, appId: String, attributes: WepinPinAttributes) {
        self.appKey = appKey
        self.appId = appId
        self.attributes = attributes
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setWebViewUrl()
    }

    private func configureWebView() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true
        webView = WKWebView(frame: view.bounds, configuration: webConfiguration)
        webView?.translatesAutoresizingMaskIntoConstraints = false
        webView?.uiDelegate = self
        webView?.navigationDelegate = self
        webView?.isOpaque = false
        webView?.backgroundColor = .clear
        webView?.scrollView.backgroundColor = .clear

        view.addSubview(webView!)
        NSLayoutConstraint.activate([
            webView!.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView!.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        webView?.configuration.userContentController.add(self, name: "post")
    }


    
    private func setWebViewUrl() {
        if self.appKey!.hasPrefix("ak_dev_") {
            webViewUrl = "https://dev-v1-widget.wepin.io/"
        } else if appKey!.hasPrefix("ak_test_") {
            webViewUrl = "https://stage-v1-widget.wepin.io/"
        } else if appKey!.hasPrefix("ak_live_") {
            webViewUrl = "https://v1-widget.wepin.io/"
        } else {
            webViewUrl = nil
            print("App Key is not set")
        }
    }

    public func openWepinWidget() {
        configureWebView()
        guard let url = URL(string: webViewUrl!) else {
            print("Invalid URL format")
            return
        }
        let loadUrl = URLRequest(url: url)
        webView?.load(loadUrl)
    }

    @objc private func tapToClose() {
        dismiss(animated: true)
    }

    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let urlString = navigationAction.request.url?.absoluteString, let url = URL(string: urlString) else {
            print("Invalid URL format")
            return nil
        }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
        return nil
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // message.name : webview <=> native 자바스크립트 인터페이스 명
        switch message.name {
        case "post":
            processPost(messageBody: message.body)
        default:
            break
        }
    }

    private func processPost(messageBody: Any) {
        // 웹뷰에서 받은 데이터를 처리하는 함수
        //print("processPost : ", messageBody)
    
        guard let messageString = messageBody as? String else {
            print("Invalid message format: not a string")
            return
        }
        
        guard let jsonData = messageString.data(using: .utf8) else {
            print("Invalid JSON string")
            return
        }
        
        do {
            if let messageDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                // 4. header와 body를 파싱
                guard let header = messageDict["header"] as? [String: Any],
                      let body = messageDict["body"] as? [String: Any],
                      let command = body["command"] as? String else {
                    print("Invalid message format: missing required fields")
                    return
                }

                var jsResponse: JSResponse? = nil

                switch command {
                case Command.CMD_READY_TO_WIDGET:
                    print("CMD_READY_TO_WIDGET")
                    guard let id = header["id"] as? Int,
                          let requestTo = header["request_to"] as? String,
                          let requestFrom = header["request_from"] as? String else {
                            print("Invalid message format: missing required fields")
                            return
                        }
                    // 필요한 추가 처리 로직 구현
                    let appKey = self.appKey!
                    let appId = self.appId!
                    let domain = Bundle.main.bundleIdentifier!
                    let platform = 3  // iOS SDK platform number
                    let type = "ios-pin"
                    let version = PodVersion
                    let attributes = self.attributes!
                    
                    let storageData = StorageManager.shared.getAllStorage()
                    let storageDataAsAnyCodable = convertToAnyCodableDictionary(storageData)
                    
                    let readyData = JSResponse.Builder.ReadyToWidgetBodyData(
                        appKey: appKey,
                        appId: appId,
                        domain: domain,
                        platform: platform,
                        type: type,
                        version: version,
                        localData: storageDataAsAnyCodable,
                        attributes: attributes
                    )

                    let responseBuilder = JSResponse.Builder(id: "\(id)", requestFrom: requestFrom, command: command, state: State.STATE_SUCCESS)
                    responseBuilder.setBodyData(parameter: readyData.toDictionary())
                    jsResponse = responseBuilder.build()
                    
                case Command.CMD_GET_SDK_REQUEST:
                    print("CMD_GET_SDK_REQUEST")
                    // CMD_GET_SDK_REQUEST에 대한 응답 생성
                    
                    guard let id = header["id"] as? Int,
                          let requestTo = header["request_to"] as? String,
                          let requestFrom = header["request_from"] as? String else {
                            print("Invalid message format: missing required fields")
                            return
                        }

                    let responseBuilder = JSResponse.Builder(id: "\(id)", requestFrom: requestFrom, command: command, state: State.STATE_SUCCESS)
                    if let currentRequest = currentWepinRequest {
                        // currentWepinRequest가 nil이 아닌 경우
                        let responseDataAsAnyCodable = convertToAnyCodableDictionary(currentRequest)
                        responseBuilder.setBodyData(parameter: responseDataAsAnyCodable)
                    } else {
                        // currentWepinRequest가 nil인 경우
                        responseBuilder.setBodyData(parameter: AnyCodable("No Request"))
                    }
                    
                    jsResponse = responseBuilder.build()

                case Command.CMD_SET_LOCAL_STORAGE:
                    print("CMD_SET_LOCAL_STORAGE")
                    guard let id = header["id"] as? Int,
                          let requestTo = header["request_to"] as? String,
                          let requestFrom = header["request_from"] as? String else {
                        print("Invalid message format: missing required fields")
                        return
                    }

                    do {
                        // 'parameter' 객체에서 'data'를 가져옴
                        guard let bodyObject = body["parameter"] as? [String: Any],
                              let dataObject = bodyObject["data"] as? [String: Any] else {
                            print("Invalid parameter format")
                            return
                        }

                        var storageDataMap: [String: Codable] = [:]

                        // 데이터 처리 로직 구현
                        for (key, value) in dataObject {
                            let storageValue: Codable
                            if let jsonObject = value as? [String: Any] {
                                // Dictionary를 JSON String으로 변환
                                if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []),
                                   let jsonString = String(data: jsonData, encoding: .utf8) {
                                    storageValue = jsonString
                                } else {
                                    throw NSError(domain: "JSONSerialization", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON to String"])
                                }
                            } else if let stringValue = value as? String {
                                // String 값 처리
                                storageValue = stringValue
                            } else if let intValue = value as? Int {
                                // Int 값 처리
                                storageValue = intValue
                            } else {
                                // 지원되지 않는 데이터 타입 예외 처리
                                throw NSError(domain: "UnsupportedDataType", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unsupported data type for key: \(key)"])
                            }
                            // 처리된 값을 storageDataMap에 추가
                            storageDataMap[key] = storageValue
                        }

                        // StorageManager에 데이터 설정
                        for (key, value) in storageDataMap {
                            StorageManager.shared.setStorage(key: key, data: value)
                        }

                        // 성공적인 JSResponse 객체 생성
                        let responseBuilder = JSResponse.Builder(id: "\(id)", requestFrom: requestFrom, command: command, state: State.STATE_SUCCESS)
                        jsResponse = responseBuilder.build()
                        
                    } catch {
                        print("Error processing JSON data: \(error.localizedDescription)")
                        // 에러 발생 시 실패 상태로 응답 설정
                        let responseBuilder = JSResponse.Builder(id: "\(id)", requestFrom: requestFrom, command: command, state: State.STATE_ERROR)
                        responseBuilder.setBodyData(parameter: ["message": AnyCodable("Error processing data: \(error.localizedDescription)")])
                        jsResponse = responseBuilder.build()
                    }

                case Command.CMD_CLOSE_WEPIN_WIDGET:
                    print("CMD_CLOSE_WEPIN_WIDGET")
                    guard let id = header["id"] as? Int,
                          let requestTo = header["request_to"] as? String,
                          let requestFrom = header["request_from"] as? String else {
                        print("Invalid message format: missing required fields")
                        return
                    }
                    // 성공적인 JSResponse 객체 생성
                    let responseBuilder = JSResponse.Builder(id: "\(id)", requestFrom: requestFrom, command: command, state: State.STATE_SUCCESS)
                    jsResponse = responseBuilder.build()
                    self.dismiss(animated: true)
                    
                // CMD_GET_SDK_REQUEST 에 요청했던 command에 대한 웹뷰 응답처리
                // CMD_SUB_XXXX 요청 헤더 필드값들은 CMD_XXXXX 와 다름!!
                case Command.CMD_SUB_PIN_REGISTER:
                    print("CMD_SUB_PIN_REGISTER")
                    guard let id = header["id"] as? Int,
                          let requestTo = header["response_from"] as? String,
                          let requestFrom = header["response_to"] as? String else {
                        print("Invalid message format: missing required fields")
                        return
                    }
                    
                    let responseBuilder = JSResponse.Builder(id: "\(id)", requestFrom: requestTo, command: command, state: State.STATE_SUCCESS)
                    jsResponse = responseBuilder.build()
                    
                    if let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                       let body = jsonObject["body"] as? [String: Any] {
                        
                        // 에러 상태인지 확인
                        if let state = body["state"] as? String, state == "ERROR" {
                            // 에러 상태일 경우 처리
                            if let errorData = body["data"] as? String {
                                print("Error state detected: \(errorData)")
                                if let currentResponseDeferred = ResponseHandler.shared.currentResponseDeferred {
                                    // 에러 메시지를 JSON 문자열로 전달
                                    currentResponseDeferred("{\"error\": \"\(errorData)\"}")
                                }
                            } else {
                                print("Error state detected but no data provided")
                                
                            }
                            break // 에러 상태 처리 후 종료
                        }
                        
                        // 정상적인 데이터 처리
                        if let data = body["data"] as? [String: Any] {
                            if let currentResponseDeferred = ResponseHandler.shared.currentResponseDeferred {
                                do {
                                    // RegistrationPinBlock 생성
                                    let registerPinBlock = try RegistrationPinBlock.fromJson(data)
                                    
                                    // RegistrationPinBlock을 JSON으로 변환
                                    let jsonData = try JSONSerialization.data(withJSONObject: registerPinBlock.toJson(), options: [])
                                    let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
                                    
                                    // currentResponseDeferred에 JSON 문자열 전달
                                    currentResponseDeferred(jsonString)
                                } catch {
                                    print("Failed to create RegistrationPinBlock from data: \(error)")
                                }
                            } else {
                                print("No currentResponseDeferred handler available")
                            }
                        } else {
                            print("Failed to parse jsonData or find data")
                        }
                    } else {
                        print("Failed to parse jsonData")
                    }

                case Command.CMD_SUB_PIN_AUTH:
                    print("CMD_SUB_PIN_AUTH")
                    guard let id = header["id"] as? Int,
                          let requestTo = header["response_from"] as? String,
                          let requestFrom = header["response_to"] as? String else {
                        print("Invalid message format: missing required fields")
                        return
                    }

                    let responseBuilder = JSResponse.Builder(id: "\(id)", requestFrom: requestTo, command: command, state: State.STATE_SUCCESS)
                    jsResponse = responseBuilder.build()

                    if let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                       let body = jsonObject["body"] as? [String: Any] {
                        
                        // 에러 상태인지 확인
                        if let state = body["state"] as? String, state == "ERROR" {
                            // 에러 상태일 경우 처리
                            if let errorData = body["data"] as? String {
                                print("Error state detected: \(errorData)")
                                if let currentResponseDeferred = ResponseHandler.shared.currentResponseDeferred {
                                    // 에러 메시지를 JSON 문자열로 전달
                                    currentResponseDeferred("{\"error\": \"\(errorData)\"}")
                                }
                            } else {
                                print("Error state detected but no data provided")
                            }
                            return // 에러 상태 처리 후 종료
                        }

                        // 정상적인 데이터 처리
                        if let data = body["data"] as? [String: Any] {
                            if let currentResponseDeferred = ResponseHandler.shared.currentResponseDeferred {
                                do {
                                    // AuthPinBlock 생성
                                    let authPinBlock = try AuthPinBlock.fromJson(data)
                                    
                                    // AuthPinBlock을 JSON으로 변환
                                    let jsonData = try JSONSerialization.data(withJSONObject: authPinBlock.toJson(), options: [])
                                    let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
                                    
                                    // currentResponseDeferred에 JSON 문자열 전달
                                    currentResponseDeferred(jsonString)
                                } catch {
                                    print("Failed to create AuthPinBlock from data: \(error)")
                                }
                            } else {
                                print("No currentResponseDeferred handler available")
                            }
                        } else {
                            print("Failed to parse jsonData or find data")
                        }
                    } else {
                        print("Failed to parse jsonData")
                    }

                case Command.CMD_SUB_PIN_CHANGE:
                    print("CMD_SUB_PIN_CHANGE")
                    guard let id = header["id"] as? Int,
                          let requestTo = header["response_from"] as? String,
                          let requestFrom = header["response_to"] as? String else {
                        print("Invalid message format: missing required fields")
                        return
                    }

                    let responseBuilder = JSResponse.Builder(id: "\(id)", requestFrom: requestTo, command: command, state: State.STATE_SUCCESS)
                    jsResponse = responseBuilder.build()
                    
                    

                    if let jsonData = messageString.data(using: .utf8),
                       let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                       let body = jsonObject["body"] as? [String: Any] {

                        // 에러 상태인지 확인
                        if let state = body["state"] as? String, state == "ERROR" {
                            // 에러 상태일 경우 처리
                            if let errorData = body["data"] as? String {
                                print("Error state detected: \(errorData)")
                                if let currentResponseDeferred = ResponseHandler.shared.currentResponseDeferred {
                                    // 에러 메시지를 JSON 문자열로 전달
                                    currentResponseDeferred("{\"error\": \"\(errorData)\"}")
                                }
                            } else {
                                print("Error state detected but no data provided")
                            }
                            return // 에러 상태 처리 후 종료
                        }

                        // 정상적인 데이터 처리
                        if let data = body["data"] as? [String: Any] {
                            if let currentResponseDeferred = ResponseHandler.shared.currentResponseDeferred {
                                do {
                                    // ChangePinBlock 생성
                                    let changePinBlock = try ChangePinBlock.fromJson(data)
                                    
                                    // ChangePinBlock을 JSON으로 변환
                                    let jsonData = try JSONSerialization.data(withJSONObject: changePinBlock.toJson(), options: [])
                                    let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
                                    
                                    // currentResponseDeferred에 JSON 문자열 전달
                                    currentResponseDeferred(jsonString)
                                } catch {
                                    print("Failed to create ChangePinBlock from data: \(error)")
                                }
                            } else {
                                print("No currentResponseDeferred handler available")
                            }
                        } else {
                            print("Failed to parse messageString or find data")
                        }
                    } else {
                        print("Failed to parse messageString")
                    }

                case Command.CMD_SUB_PIN_OTP:
                    print("CMD_SUB_PIN_OTP")
                    guard let id = header["id"] as? Int,
                          let requestTo = header["response_from"] as? String,
                          let requestFrom = header["response_to"] as? String else {
                        print("Invalid message format: missing required fields")
                        return
                    }

                    let responseBuilder = JSResponse.Builder(id: "\(id)", requestFrom: requestTo, command: command, state: State.STATE_SUCCESS)
                    jsResponse = responseBuilder.build()
                    
                    if let jsonData = messageString.data(using: .utf8),
                       let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                       let body = jsonObject["body"] as? [String: Any] {
                        
                        // 에러 상태인지 확인
                        if let state = body["state"] as? String, state == "ERROR" {
                            // 에러 상태일 경우 처리
                            if let errorData = body["data"] as? String {
                                print("Error state detected: \(errorData)")
                                if let currentResponseDeferred = ResponseHandler.shared.currentResponseDeferred {
                                    // 에러 메시지를 JSON 문자열로 전달
                                    currentResponseDeferred("{\"error\": \"\(errorData)\"}")
                                }
                            } else {
                                print("Error state detected but no data provided")
                            }
                            return // 에러 상태 처리 후 종료
                        }
                        
                        // 정상적인 데이터 처리
                        if let data = body["data"] as? [String: Any] {
                            if let currentResponseDeferred = ResponseHandler.shared.currentResponseDeferred {
                                do {
                                    // AuthOTP 생성
                                    let authOtp = try AuthOTP.fromJson(data)
                                    
                                    // AuthOTP를 JSON으로 변환
                                    let jsonData = try JSONSerialization.data(withJSONObject: authOtp.toJson(), options: [])
                                    let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
                                    
                                    // currentResponseDeferred에 JSON 문자열 전달
                                    currentResponseDeferred(jsonString)
                                } catch {
                                    print("Failed to create AuthOTP from data: \(error)")
                                }
                            } else {
                                print("No currentResponseDeferred handler available")
                            }
                        } else {
                            print("Failed to parse messageString or find data")
                        }
                    } else {
                        print("Failed to parse messageString")
                    }

                default:
                    print("Unknown command")
                }

                // 7. JSResponse가 nil이 아닌 경우 JSON으로 변환하여 출력
                if let jsResponse = jsResponse {
                    do {
                        let responseData = try JSONEncoder().encode(jsResponse)
                        if let responseString = String(data: responseData, encoding: .utf8) {
                            //print("JSProcessor Response: \(responseString)")
                            
                            // 웹뷰가 존재하는지 안전하게 체크
                            guard let webView = self.webView else {
                                print("Error: WebView is nil")
                                
                                return
                            }
                            
                            // 웹뷰로 응답 전송
                            sendResponseToWebView(response: responseString, webView: webView)
      
                        }
                    } catch {
                        print("Error encoding JSResponse: \(error.localizedDescription)")
                    }
                } else {
                    print("Error: jsResponse is nil")
                }

            } else {
                print("Failed to parse JSON into dictionary")
            }
        } catch {
            print("Error parsing JSON: \(error)")
        }
    }

    // 웹뷰에 응답하는 함수
    private func sendResponseToWebView(response: String, webView: WKWebView) {
        // JavaScript 실행을 통해 웹뷰로 응답을 전송
        let message = "onResponse(" + response + ");"
        webView.evaluateJavaScript(message) { (result, error) in
            if let error = error {
                print("Error executing JS command: \(error.localizedDescription)")
            }
        }
    }
}
