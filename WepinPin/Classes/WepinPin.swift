import Foundation
import WepinCommon
import WepinModal
import WepinLogin
import WepinCore

public class WepinPin {
    private var initialized: Bool = false
    private let wepinPinManager: WepinPinManager
    private let wepinPinParams: WepinPinParams
    private let platformType: String
    
    public var login: WepinLogin? {
        return wepinPinManager.wepinLoginLib
    }
    
    //MARK: - Initialization
    public init(_ params: WepinPinParams, platformType: String = "ios") {
        self.wepinPinParams = params
        self.platformType = platformType
        self.wepinPinManager = WepinPinManager.shared
    }
    
    //MARK: - Public Methods
    public func initialize(attributes: WepinPinAttributes) async throws -> Bool {
        if initialized {
            throw WepinError.alreadyInitialized
        }
        
        try await wepinPinManager.initialize(params: wepinPinParams, attributes: attributes, platformType: platformType)
        
        initialized = true
        

        _ = await WepinCore.shared.session.checkLoginStatusAndGetLifeCycle()
        return initialized
    }
    
    public func finalize() {
        guard initialized else {
            return
        }
        
        wepinPinManager.finalize()
        initialized = false
    }
    
    public func isInitialized() -> Bool {
        return initialized
    }
    
    public func changeLanguage(language: String) {
        wepinPinManager.wepinAttributes?.defaultLanguage = language
    }
    
    public func generateRegistrationPINBlock(viewController: UIViewController? = nil) async throws -> RegistrationPinBlock? {
        return try await executePinCommand(command: Command.CMD_SUB_PIN_REGISTER, parameter: nil, viewController: viewController, parseResult: {resultDict in
            try RegistrationPinBlock.fromJson(resultDict)
        })
    }
    
    public func generateAuthPINBlock(count: Int?, viewController: UIViewController? = nil) async throws -> AuthPinBlock? {
//        let actualCnt = count ?? 1
        let actualCnt: Int
        if let count = count, count > 0 {
            actualCnt = count        // 첫 번째 할당 (초기화)
        } else {
            actualCnt = 1           // 첫 번째 할당 (초기화)
        }
        let param: [String: Int?] = ["count": actualCnt]
        return try await executePinCommand(command: Command.CMD_SUB_PIN_AUTH, parameter: param, viewController: viewController, parseResult: { resultDict in
            try AuthPinBlock.fromJson(resultDict)
        })
    }
    
    public func generateChangePINBlock(viewController: UIViewController? = nil) async throws -> ChangePinBlock? {
        return try await executePinCommand(command: Command.CMD_SUB_PIN_CHANGE, parameter: nil, viewController: viewController, parseResult: { resultDict in
            try ChangePinBlock.fromJson(resultDict)
        })
    }
    
    public func generateAuthOTPCode(viewController: UIViewController? = nil) async throws -> AuthOTP? {
        return try await executePinCommand(command: Command.CMD_SUB_PIN_OTP, parameter: nil, viewController: viewController, parseResult: { resultDict in
            try AuthOTP.fromJson(resultDict)
        })
    }
    
    private func executePinCommand<T>(command: String, parameter: Any?, viewController: UIViewController?, parseResult: ([String: Any]) throws -> T?) async throws -> T? {
        guard initialized else { throw WepinError.notInitialized }
        let lifeCycle = await WepinCore.shared.session.checkLoginStatusAndGetLifeCycle()
        if (lifeCycle == .login || lifeCycle == .loginBeforeRegister) {
            guard let tobViewController = viewController ?? getTopViewController() else {
                throw WepinError.unknown("UIViewController not found")
            }
            let result = try await wepinPinManager.wepinWebViewManager?.openWidgetWithCommand(
                viewController: tobViewController,
                command: command,
                parameter: parameter as? [String : Any]
            )
            
            if let result = result,
               let jsonData = result.data(using: .utf8),
               let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let body = json["body"] as? [String: Any],
               let state = body["state"] as? String,
               state == "SUCCESS" {
                guard let data = body["data"] as? [String: Any] else {
                    throw WepinError.unknown("invalid response")
                }
                return try parseResult(data)
            } else if let jsonData = result?.data(using: .utf8),
                      let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                      let body = json["body"] as? [String: Any],
                      let errorMsg = body["data"] as? String {
                throw WepinError.unknown(errorMsg)
            } else {
                throw WepinError.networkError("")
            }
        } else {
            throw WepinError.invalidLoginSession("")
        }
    }
    
    private func getTopViewController() -> UIViewController? {
        if Thread.isMainThread {
            return _getTopViewController()
        } else {
            var result: UIViewController?
            DispatchQueue.main.sync {
                result = _getTopViewController()
            }
            return result
        }
    }
    
    private func _getTopViewController() -> UIViewController? {
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }

        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }
        return topVC
    }
}
    
