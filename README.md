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

> ⚠️ Important Notice for v1.0.0 Update
>
> 🚨 Breaking Changes & Migration Guide 🚨
>
> This update includes major changes that may impact your app. Please read the following carefully before updating.
>
> 🔄 Storage Migration
> •    In rare cases, stored data may become inaccessible due to key changes.
> •    Starting from v1.0.0, if the key is invalid, stored data will be cleared, and a new key will be generated automatically.
> •    Existing data will remain accessible unless a key issue is detected, in which case a reset will occur.
> •    ⚠️ Downgrading to an older version after updating to v1.0.0 may prevent access to previously stored data.
> •    Recommended: Backup your data before updating to avoid any potential issues.
>
> 📦 Compatibility with WepinLogin
> •    If you are using this module alongside WepinLogin, please ensure that you are also using `WepinLogin` v1.0.0 or higher.
> •    Mixing different major versions of Wepin modules may result in compatibility issues, unexpected errors, or inconsistent behavior.
> •    For a stable integration, always use v1.0.0+ across all Wepin modules together.

>🆕 What's New in v1.1.0
> ✅ WepinPin now includes WepinLogin by default. • Starting from v1.1.0, the WepinLogin module is bundled within WepinPin.
> • You no longer need to install or manage WepinLogin separately when using WepinPin.
> • This simplifies integration and reduces dependency management for login-related features. • For consistent behavior, please ensure all Wepin modules used are updated to v1.1.0 or higher.


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
wepinPin = WepinPin(initParam)

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
 - `viewController` \<UIViewController> __optional__ - The view controller from which the login widget (WebView) will be presented modally. It provides the display context to ensure the widget appears on the correct screen.

> [!NOTE]
> You may optionally provide a UIViewController as a parameter.
> If provided, the WebView will be presented using the given controller.
> If omitted, the SDK will automatically attempt to find the top-most UIViewController on the main thread.
> 
> In some cases (e.g., during modal presentation or custom containers), automatic detection of the top view controller may fail. It is recommended to explicitly pass a UIViewController when possible.
   
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
  - `viewController` \<UIViewController> __optional__ - The view controller from which the login widget (WebView) will be presented modally. It provides the display context to ensure the widget appears on the correct screen.

> [!NOTE]
> You may optionally provide a UIViewController as a parameter.
> If provided, the WebView will be presented using the given controller.
> If omitted, the SDK will automatically attempt to find the top-most UIViewController on the main thread.
> 
> In some cases (e.g., during modal presentation or custom containers), automatic detection of the top view controller may fail. It is recommended to explicitly pass a UIViewController when possible.
   
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
 - `viewController` \<UIViewController> __optional__ - The view controller from which the login widget (WebView) will be presented modally. It provides the display context to ensure the widget appears on the correct screen.

> [!NOTE]
> You may optionally provide a UIViewController as a parameter.
> If provided, the WebView will be presented using the given controller.
> If omitted, the SDK will automatically attempt to find the top-most UIViewController on the main thread.
> 
> In some cases (e.g., during modal presentation or custom containers), automatic detection of the top view controller may fail. It is recommended to explicitly pass a UIViewController when possible.
   
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
 - `viewController` \<UIViewController> __optional__ - The view controller from which the login widget (WebView) will be presented modally. It provides the display context to ensure the widget appears on the correct screen.

> [!NOTE]
> You may optionally provide a UIViewController as a parameter.
> If provided, the WebView will be presented using the given controller.
> If omitted, the SDK will automatically attempt to find the top-most UIViewController on the main thread.
> 
> In some cases (e.g., during modal presentation or custom containers), automatic detection of the top view controller may fail. It is recommended to explicitly pass a UIViewController when possible.
   
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


