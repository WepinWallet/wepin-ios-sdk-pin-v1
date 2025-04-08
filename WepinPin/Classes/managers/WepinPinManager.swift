import Foundation
import WepinCommon
import WepinModal
import WepinLogin
import WepinSession
import WepinNetwork
import WepinStorage

public class WepinPinManager {
    // MARK: - Singleton
    static let shared = WepinPinManager()
    private init() {}
    
    // MARK: - Properties
//    var wepinNetwork: WepinNetwork?
    var wepinWebViewManager: WepinWebViewManager?
    var wepinLoginLib: WepinLogin?
    var appId: String = ""
    var appKey: String = ""
    var domain: String = ""
    var version: String = ""
    var sdkType: String = ""
    var wepinAttributes: WepinAttributeWithProviders?
    var loginProviderInfos: [LoginProviderInfo] = []
    internal var currentWepinRequest: [String: Any]? = nil
    public var currentViewController: UIViewController?
    
    // MARK: - Public Methods
    func initialize(params: WepinPinParams, attributes: WepinPinAttributes, platformType: String? = "ios") async throws {
        appId = params.appId
        appKey = params.appKey
        
        guard let url = try WepinCommon.getWepinSdkUrl(appKey: appKey)["wepinWebview"] else {
            throw WepinError.invalidAppKey
        }
        
        domain = Bundle.main.bundleIdentifier ?? ""
        sdkType = "\(platformType ?? "ios")-pin"
        
        // TODO: version 가져오는 방법
        version = Bundle(for: WepinPin.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0"
        
        wepinAttributes = WepinAttributeWithProviders(defaultLanguage: attributes.defaultLanguage, defaultCurrency: attributes.defaultCurrency)
        
        try WepinNetwork.shared.initialize(appKey: appKey, domain: domain, sdkType: sdkType, version: version)
        wepinWebViewManager = WepinWebViewManager(params: params, baseUrl: url)
        WepinSessionManager.shared.initialize(appId: appId, sdkType: platformType ?? "ios")
        
        let wepinLoginParams = WepinLoginParams(appId: appId, appKey: appKey)
        wepinLoginLib = WepinLogin(wepinLoginParams)
        _ = try await wepinLoginLib?.initialize()
    }
    
    func finalize() {
        wepinLoginLib?.finalize()
//        wepinNetwork = nil
        WepinNetwork.shared.finalize()
        wepinWebViewManager = nil
        WepinSessionManager.shared.finalize()
        wepinAttributes = nil
        loginProviderInfos.removeAll()
        currentWepinRequest = nil
        wepinLoginLib = nil
    }
}
