import Foundation
import WepinCommon
import WepinModal
import WepinLogin
import WepinCore

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
        
        try await WepinCore.shared.initialize(appId: appId, appKey: appKey, domain: domain, sdkType: sdkType, version: version)
        wepinWebViewManager = WepinWebViewManager(params: params, baseUrl: url)
        
        let wepinLoginParams = WepinLoginParams(appId: appId, appKey: appKey)
        wepinLoginLib = WepinLogin(wepinLoginParams)
        _ = try await wepinLoginLib?.initialize()
    }
    
    func finalize() {
        wepinLoginLib?.finalize()
        WepinCore.shared.finalize()
        wepinWebViewManager = nil
        wepinAttributes = nil
        loginProviderInfos.removeAll()
        currentWepinRequest = nil
        wepinLoginLib = nil
    }
}
