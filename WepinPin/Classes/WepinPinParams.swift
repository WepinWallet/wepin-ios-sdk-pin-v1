
import Foundation

public struct WepinPinParams: Codable {
    public var appId: String
    public var appKey: String
    
    public init(appId: String, appKey: String){
        self.appId = appId
        self.appKey = appKey
    }

}


