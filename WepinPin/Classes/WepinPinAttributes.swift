import Foundation


public struct WepinPinAttributes: Codable {
    public var defaultLanguage: String?
    
    public init(language: String){
        self.defaultLanguage = language
    }
}


