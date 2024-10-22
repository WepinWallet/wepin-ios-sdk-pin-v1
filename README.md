<br/>

<p align="center">
  <a href="https://www.wepin.io/">
      <picture>
        <source media="(prefers-color-scheme: dark)">
        <img alt="wepin logo" src="https://github.com/WepinWallet/wepin-web-sdk-v1/blob/main/assets/wepin_logo_color.png?raw=true" width="250" height="auto">
      </picture>
</a>
</p>

<br>

# Wepin iOS SDK PIN Pad Library v1

Wepin Pin Pad library for iOS. This package is exclusively available for use in iOS environments.

## ⏩ Get App ID and Key
After signing up for [Wepin Workspace](https://workspace.wepin.io/), go to the development tools menu and enter the information for each app platform to receive your App ID and App Key.

## ⏩ Requirements
- iOS 13+
- Swift 5.x

## ⏩ Installation

WepinPin is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'WepinPin'
```

## ⏩ Getting Started
### Import WepinPin into your project.
```swift
import WepinPin
```

## ⏩ Initialize
Before using the created instance, initialize it using the App ID and App Key.

  ```swift
let appKey: String = "Wepin-App-Key"
let appId: String = "Wepin-App-ID"
var wepinPin: WepinPin? = nil
let initParam = WepinPinParams(appId: appId, appKey: appKey)
wepin = WepinPin(initParam)

  ```

### init

```swift
await wepinPin?.initialize(attributes: attributes)
```

#### Parameters
- `attributes` \<WepinPinAttributes> 
  - `defaultLanguage` \<String> - The language to be displayed on the widget (default: 'en'). Currently, only 'ko', 'en', and 'ja' are supported.

#### Returns
- \<Bool>
  -  Returns `true` if success

#### Example
```swift
let attributes = WepinPinAttributes(language: "en")
if let res = try await wepinPin?.initialize(attributes: attributes) {
    print("Successed: \(res)")
} else {
    print("Failed")
}
```

### isInitialized

```swift
wepinPin!.isInitialized()
```

The `isInitialized()` method checks if the Wepin PinPad Libarary is initialized.

#### Returns

- \<Bool> - Returns `true` if  Wepin PinPad Libarary is already initialized, otherwise false.


### changeLanguage

```swift
wepinPin!.changeLanguage(language: "ko")
```

The `changeLanguage()` method changes the language of the widget.

#### Parameters
- `language` \<String> - The language to be displayed on the widget. Currently, only 'ko', 'en', and 'ja' are supported.

#### Returns
- \<Void>

#### Example

```swift
wepinPin!.changeLanguage(language: "ko")
```

## ⏩ Method & Variable

Methods and Variables can be used after initialization of Wepin PIN Pad Library.

### generateRegistrationPINBlock
```swift
await wepinPin!.generateRegistrationPINBlock()
```
Generates a pin block for registration. 
This method should only be used when the loginStatus is pinRequired.

#### Parameters
 - void
   
#### Returns
 - \<RegistrationPinBlock>
   - uvd: \<EncUVD> - Encrypted PIN
     - b64Data \<String> - Data encrypted with the original key in b64SKey
     - b64SKey \<String> - A key that encrypts data encrypted with the Wepin's public key.
     - seqNum \<Int> - __optional__ Values to check for when using PIN numbers to ensure they are used in order.
   - hint: \<EncPinHint> - Hints in the encrypted PIN.
     - data \<String> - Encrypted hint data.
     - length \<String> - The length of the hint
     - version \<Int> - The version of the hint

#### Example
```swift
do{
  let registrationPinBlock = try await wepinPin!.generateRegistrationPINBlock()
  if let registerPinBlock = registrationPinBlock {
  // You need to make a Wepin RESTful API request using the received data.  
  }
}catch(let error){
  print(error)
}

```

### generateAuthPINBlock
```swift
await wepinPin!.generateAuthPINBlock(3)
```
Generates a pin block for authentication.

#### Parameters
  - `count` \<Int> - __optional__ If multiple PIN blocks are needed, please enter the number to generate. If the count value is not provided, it will default to 1.
   
#### Returns
 - \<AuthPinBlock>
   - uvdList: \<List<EncUVD>> - Encypted pin list
     - b64Data \<String> - Data encrypted with the original key in b64SKey
     - b64SKey \<String> - A key that encrypts data encrypted with the wepin's public key.
     - seqNum \<Int> - __optional__ Values to check for when using PIN numbers to ensure they are used in order
   - otp \<String> - __optional__ If OTP authentication is required, include the OTP.

#### Example
```swift    
do{
  let authPinBlock = try await wepinPin!.generateAuthPINBlock(3)
  if let authPinBlock = authPinBlock {
    // You need to make a Wepin RESTful API request using the received data.  
  }
}catch(let error){
  print(error)
}
```

### generateChangePINBlock
```swift
await wepinPin!.generateChangePINBlock()
```
Generate pin block for changing the PIN.

#### Parameters
 - \<Void>
   
#### Returns
 - \<ChangePinBlock>
   - uvd: \<EncUVD> - Encrypted PIN
     - b64Data \<String> - Data encrypted with the original key in b64SKey
     - b64SKey \<String> - A key that encrypts data encrypted with the wepin's public key.
     - seqNum \<Int> - __optional__ Values to check for when using PIN numbers to ensure they are used in order
   - newUVD: \<EncUVD> - New encrypted PIN
     - b64Data \<String> - Data encrypted with the original key in b64SKey
     - b64SKey \<String> - A key that encrypts data encrypted with the wepin's public key.
     - seqNum \<Int> - __optional__ Values to check for when using PIN numbers to ensure they are used in order
   - hint: \<EncPinHint> - Hints in the encrypted PIN
     - data \<String> - Encrypted hint data
     - length \<String> - The length of the hint
     - version \<Int> - The version of the hint
   - otp \<String> - __optional__ If OTP authentication is required, include the OTP.

#### Example
```swift    
do{
  let changepPinBlock = try await wepinPin!.generateChangePINBlock()
  if let changepPinBlock = changePinBlock {
    // You need to make a Wepin RESTful API request using the received data.  
  }
}catch(let error){
  print(error)
}
```

### generateAuthOTP
```swift
await wepinPin!.generateAuthOTPCode()
```
generate OTP.

#### Parameters
 - void
   
#### Returns
 - \<AuthOTP>
   - code \<String> - __optional__ The OTP entered by the user.

```swift    
do{
  let authOTPCode = try await wepinPin!.generateAuthOTPCode()
  if let authOTPCode = authOTPCode {
    // You need to make a Wepin RESTful API request using the received data.  
  }
}catch(let error){
  print(error)
}
```

### finalize
```swift
wepinPin!.finalize()
```

The `finalize()` method finalizes the Wepin PinPad Libarary.

#### Parameters
 - void
#### Returns
 - void

#### Example
```swift
wepinPin!.finalize()
```

## ⏩ Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.


