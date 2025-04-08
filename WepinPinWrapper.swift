//
//  WepinPinWrapper.swift
//  Pods
//
//  Created by iotrust on 3/25/25.
//

@objc public class WepinPinWrapper: NSObject {
    private var pin: WepinPin?
    
    @objc public init(appId: String, appKey: String, sdkType: String = "ios") {
        super.init()
        let params = WepinPinParams(appId: appId, appKey: appKey)
        self.pin = WepinPin(params, platformType: sdkType)
    }
    
    @objc public func initialize(params: NSDictionary, completion: @escaping (Bool, NSError?) -> Void) {
        guard let defaultLanguage = params["defaultLanguage"] as? String,
              let defaultCurrency = params["defaultCurrency"] as? String else {
            completion(false, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Parameters"]))
            return
        }
        Task {
            do {
                let initParams = WepinPinAttributes(defaultLanguage: defaultLanguage, defaultCurrency: defaultCurrency)
                let result = try await self.pin?.initialize(attributes: initParams)
                completion(result ?? false, nil)
            } catch {
                completion(false, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
            }
        }
    }
    
    @objc public func finalizeWepinPin() {
        self.pin?.finalize()
    }
    
    @objc public func isInitialized() -> Bool {
        let result = self.pin?.isInitialized()
        return result ?? false
    }
    
    @objc public func changeLanguage(language: String) {
        self.pin?.changeLanguage(language: language)
    }
    
    @objc public func generateRegistrationPINBlock(completion: @escaping (NSDictionary?, NSError?) -> Void) {
        Task {
            do {
                let result: RegistrationPinBlock? = try await self.pin?.generateRegistrationPINBlock()
                completion(["registrationPinBlock": result?.toDictionary()] as? NSDictionary, nil)
            } catch {
                completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
            }
        }
    }
    
    @objc public func generateAuthPINBlock(count: NSNumber?, completion: @escaping (NSDictionary?, NSError?) -> Void) {
        Task {
            do {
                let countValue = (count)?.intValue ?? 1
                let result: AuthPinBlock? = try await self.pin?.generateAuthPINBlock(count: countValue)
                completion(["authPinBlock": result?.toDictionary()] as? NSDictionary, nil)
            } catch {
                completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
            }
        }
    }
    
    @objc public func generateChangePINBlock(completion: @escaping (NSDictionary?, NSError?) -> Void) {
        Task {
            do {
                let result: RegistrationPinBlock? = try await self.pin?.generateRegistrationPINBlock()
                completion(["registrationPinBlock": result?.toDictionary()] as? NSDictionary, nil)
            } catch {
                completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
            }
        }
    }
    
    @objc public func generateAuthOTPCode(completion: @escaping (NSDictionary?, NSError?) -> Void) {
        Task {
            do {
                let result: RegistrationPinBlock? = try await self.pin?.generateRegistrationPINBlock()
                completion(["registrationPinBlock": result?.toDictionary()] as? NSDictionary, nil)
            } catch {
                completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
            }
        }
    }
}
