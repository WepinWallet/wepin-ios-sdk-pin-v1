import Foundation
import UIKit
import WebKit
import WepinModal
import WepinCommon

class WepinWebViewManager {
    // MARK: - Properties
    private var webView: WKWebView?
    private let params: WepinPinParams
    private let wepinModal = WepinModal()
    private let baseUrl: String
    private var responseWepinUserSetDeferred: CheckedContinuation<Bool, Error>?
//    private var _currentWepinRequest: <String, Any?>? = null
    private var responseDeferred: CheckedContinuation<String, Error>?
    
    // MARK: - Initialization
    init(params: WepinPinParams, baseUrl: String) {
        self.params = params
        self.baseUrl = baseUrl
    }
    
    public func openWidget(viewController: UIViewController) {
        WepinPinManager.shared.currentWepinRequest = nil
        wepinModal.openModal(on: viewController, url: baseUrl, jsProcessor: JSProcessor.processRequest(request:webView:callback:))
    }
    
    public func openWidgetWithCommand(
        viewController: UIViewController,
        command: String,
        parameter: [String: Any]? = nil
    ) async throws -> String {

        let id = Int(Date().timeIntervalSince1970 * 1000)
        let finalParameter = parameter ?? [:]

        // ✅ 현재 요청 저장
        WepinPinManager.shared.currentWepinRequest = [
            "header": [
                "request_from": "native",
                "request_to": "wepin_widget",
                "id": id
            ],
            "body": [
                "command": command,
                "parameter": finalParameter
            ]
        ]

        // ✅ JSProcessor가 응답을 받을 Deferred 초기화
        setResponseDeferred()

        // ✅ Modal 열기 (메인 쓰레드에서 호출)
        DispatchQueue.main.async {
            self.wepinModal.openModal(
                on: viewController,
                url: self.baseUrl,
                jsProcessor: JSProcessor.processRequest(request:webView:callback:)
            )
        }

        do {
            // ✅ 비동기 응답 대기
            let result = try await getResponseDeferred()
            
            // ✅ 결과 파싱
            if let data = result.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let body = json["body"] as? [String: Any],
               let state = body["state"] as? String {

                if state.uppercased() == "ERROR" {
                    let errorMessage = body["data"] as? String ?? "Unknown error"
                    throw mapWebviewErrorToWepinError(errorMessage)
                } else {
                    return result
                }
            } else {
                throw WepinError.unknown("Invalid response format")
            }
        } catch {
            WepinPinManager.shared.currentWepinRequest = nil
            throw error
        }
    }
    
    func closeWidget() {
        wepinModal.closeModal()
    }
    
    // for set_local_storage 에서 유저 정보가 있는 경우 수행하기 위해
    func resetResponseWepinUserDeferred() {
        responseWepinUserSetDeferred = nil
    }
    
    func getResponseWepinUserDeferred() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            responseWepinUserSetDeferred = continuation
        }
    }
    
    func completeResponseWepinUserDeferred(success: Bool) {
        responseWepinUserSetDeferred?.resume(returning: success)
        responseWepinUserSetDeferred = nil
    }
    
    // get_sdk_request 의 request에 대한 response를 받아서 수행하기 위해
    public func setResponseDeferred() {
        responseDeferred = nil
    }

    public func getResponseDeferred() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            self.responseDeferred = continuation
        }
    }

    public func completeResponseDeferred(_ result: String) {
        responseDeferred?.resume(returning: result)
        responseDeferred = nil
    }

    public func failResponseDeferred(_ error: Error) {
        responseDeferred?.resume(throwing: error)
        responseDeferred = nil
    }
    
    func mapWebviewErrorToWepinError(_ message: String) -> WepinError {
        // 특정 문자열 매핑 예시
        if message.contains("network error") {
            return WepinError.networkError(message)
        } else if message.contains("User Cancel") {
            return WepinError.userCanceled
        } else if message.contains("Invalid App Key") {
            return WepinError.invalidAppKey
        } else if message.contains("Invalid Parameter") {
            return WepinError.invalidParameter(message)
        } else if message.contains("Invalid Login Session") {
            return WepinError.invalidLoginSession(message)
        } else if message.contains("Not Initialized") {
            return WepinError.notInitialized
        } else if message.contains("Already Initialized") {
            return WepinError.alreadyInitialized
        } else if message.contains("Failed Login") {
            return WepinError.loginFailed
        } else {
            return WepinError.unknown(message)
        }
    }
}
