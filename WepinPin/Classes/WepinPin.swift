//
//  WepinPin.swift
//  Wepin PIN Pad Library
//

import Foundation
import UIKit
import WebKit
import SafariServices

public enum WepinPinError:Error {
    case invalidParameters
    case notInitialized
    case invalidAppKey
    case invalidLoginSession
    case userCancelled
    case unkonwError(message: String)
    case alreadyInitialized
}


public class WepinPin {
    var initParams: WepinPinParams
    var initialized: Bool = false
    var wepinNetwork: WepinNework? = nil
    var webViewController: WepinWebViewController? = nil
    var attributes: WepinPinAttributes?

    public init(_ params: WepinPinParams) {
        initParams = params
        StorageManager.shared.initManager(appId: initParams.appId)
        wepinNetwork = WepinNework(appKey: initParams.appKey, sdkVersion: PodVersion)
    }

    public func initialize(attributes: WepinPinAttributes) async throws -> Bool {
        if initialized { throw WepinPinError.alreadyInitialized }
        self.attributes = attributes
        do {
            _ = try await wepinNetwork?.getAppInfo()
            try await checkLoginSession()
            initialized = true
            return true
        } catch {
            throw error
        }
    }

    public func finalize() {
        
        initialized = false
        webViewController?.dismiss(animated: true, completion: {
            self.webViewController = nil
        })
        ResponseHandler.shared.currentResponseDeferred = nil
        attributes = nil
    }


    public func isInitialized() -> Bool {
        return initialized
    }

    public func changeLanguage(language: String) {
        self.attributes?.defaultLanguage = language
    }

    public func generateRegistrationPINBlock() async throws -> RegistrationPinBlock? {
        if !initialized { throw WepinPinError.notInitialized }
        return try await executePinCommand(command: Command.CMD_SUB_PIN_REGISTER, parameter: nil, parseResult: { resultDict in
            try RegistrationPinBlock.fromJson(resultDict)
        })
    }

    public func generateAuthPINBlock(count: Int?) async throws -> AuthPinBlock? {
        if !initialized { throw WepinPinError.notInitialized }
        let actualCnt = count ?? 1 // count가 nil인 경우 1로 설정
        let param: [String: Int?] = ["count": actualCnt]
        return try await executePinCommand(command: Command.CMD_SUB_PIN_AUTH, parameter: param, parseResult: { resultDict in
            try AuthPinBlock.fromJson(resultDict)
        })
    }

    public func generateChangePINBlock() async throws -> ChangePinBlock? {
        if !initialized { throw WepinPinError.notInitialized }
        return try await executePinCommand(command: Command.CMD_SUB_PIN_CHANGE, parameter: nil, parseResult: { resultDict in
            try ChangePinBlock.fromJson(resultDict)
        })
    }

    public func generateAuthOTPCode() async throws -> AuthOTP? {
        if !initialized { throw WepinPinError.notInitialized }
        return try await executePinCommand(command: Command.CMD_SUB_PIN_OTP, parameter: nil, parseResult: { resultDict in
            try AuthOTP.fromJson(resultDict)
        })
    }

    private func executePinCommand<T>(command: String, parameter: Any?, parseResult: ([String: Any]) throws -> T?) async throws -> T? {
        guard initialized else { throw WepinPinError.notInitialized }
        try await checkLoginSession()
        try await initializeWebInterface()

        let result: Any = try await openAndRequestWepinWidgetAsync(command: command, parameter: parameter)
        webViewController?.currentWepinRequest = nil

        if let resultString = result as? String, let jsonData = resultString.data(using: .utf8) {
            do {
                if let resultDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    
                    // Check if the response contains an "error" key
                    if let errorMessage = resultDict["error"] as? String {
                        throw WepinPinError.unkonwError(message: errorMessage)
                    }

                    // If no error, parse the result as usual
                    return try parseResult(resultDict)
                }
            } catch {
                throw error
            }
        }
        throw WepinPinError.unkonwError(message: "Result is not of type String")
    }

    func openAndRequestWepinWidgetAsync(command: String, parameter: Any?) async throws -> Any {
        let id = Int(Date().timeIntervalSince1970 * 1000)
        let finalParameter = parameter ?? [String: Any]()
        
        webViewController?.currentWepinRequest = [
            "header": ["request_from": "native", "request_to": "wepin_widget", "id": id],
            "body": ["command": command, "parameter": finalParameter]
        ]
        await webViewController?.openWepinWidget()

        return try await withCheckedThrowingContinuation { continuation in
            ResponseHandler.shared.currentResponseDeferred = { responseString in
                continuation.resume(returning: responseString)
            }
        }
    }

    private func checkLoginSession() async throws {
        guard let token = StorageManager.shared.getStorage(key: "wepin:connectUser", type: StorageDataType.WepinToken.self),
              let userId = StorageManager.shared.getStorage(key: "user_id") as? String else {
            throw WepinPinError.invalidLoginSession
        }
        wepinNetwork?.setAuthToken(accessToken: token.accessToken, refreshToken: token.refreshToken)
        let accessToken = try await wepinNetwork?.getAccessToken(userId: userId)
        let newToken = StorageDataType.WepinToken(accessToken: accessToken!, refreshToken: token.refreshToken)
        StorageManager.shared.setStorage(key: "wepin:connectUser", data: newToken)
        wepinNetwork?.setAuthToken(accessToken: accessToken!, refreshToken: token.refreshToken)
    }

    private func initializeWebInterface() async throws {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.webViewController = WepinWebViewController(appKey: self.initParams.appKey, appId: self.initParams.appId, attributes: self.attributes!)
                self.presentWebViewController {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func presentWebViewController(completion: @escaping () -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("No active window scene or key window available.")
            return
        }
        rootViewController.present(self.webViewController!, animated: true, completion: completion)
    }
}

// ResponseHandler.swift (공유 싱글턴 클래스 파일)

class ResponseHandler {
    static let shared = ResponseHandler()
    var currentResponseDeferred: ((String) -> Void)?
}
