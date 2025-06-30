//
//  ViewController.swift
//  WepinLogin
//
//  Created by JisunHong1 on 03/17/2025.
//  Copyright (c) 2025 JisunHong1. All rights reserved.
//

import UIKit
import WepinPin

class ViewController: UIViewController {
    
    var wepinPin: WepinPin?
    
    var appId: String = "WEPIN_APP_ID"
    var appKey: String = "WEPIN_APP_KEY"
    
    var network: Network? = nil
    
    var registerAuthBlock: RegistrationPinBlock? = nil
    var signAuthBlock: AuthPinBlock? = nil
    var authOTPBlock: AuthOTP? = nil
    var changePinBlock: ChangePinBlock? = nil
    
    var scrollView: UIScrollView!
    var stackView: UIStackView!
    var settingsContainerView: UIView!
    var statusLabel: UILabel!
    var appIdTextField: UITextField!
    var appKeyTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = .white
        
        setupUI()
        
        let params = WepinPinParams(appId: appId, appKey: appKey)
        wepinPin = WepinPin(params)
        network = Network(appKey: appKey)
    }
    
    func setupUI() {
        // 상단 영역: 버튼 및 설정 패널이 포함된 스크롤 가능한 컨테이너 (화면의 50% 차지)
        let topContainer = UIView()
        topContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topContainer)
        
        // 하단 영역: 상태 레이블이 위치할 컨테이너
        let bottomContainer = UIView()
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomContainer)
        
        NSLayoutConstraint.activate([
            // 상단 영역: safeArea의 top부터 view의 50% 높이까지
            topContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            
            // 하단 영역: 상단 컨테이너 바로 아래부터 safeArea의 bottom까지
            bottomContainer.topAnchor.constraint(equalTo: topContainer.bottomAnchor),
            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // 상단 컨테이너 내부에 스크롤뷰 추가
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        topContainer.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topContainer.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: topContainer.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: topContainer.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: topContainer.bottomAnchor)
        ])
        
        // 스크롤뷰 내에 버튼 및 설정 패널을 담을 스택뷰 추가
        let buttonStackView = UIStackView()
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 16
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(buttonStackView)
        
        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            buttonStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            buttonStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            buttonStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
        
        // 상단 영역에 기존 UI 구성 요소 추가
        
        // 타이틀 레이블
        let titleLabel = UILabel()
        titleLabel.text = "Wepin Pin Test"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        buttonStackView.addArrangedSubview(titleLabel)
        
        settingsContainerView = UIView()
        settingsContainerView.backgroundColor = .white
        settingsContainerView.layer.cornerRadius = 8
        settingsContainerView.layer.shadowColor = UIColor.black.cgColor
        settingsContainerView.layer.shadowOpacity = 0.2
        settingsContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        settingsContainerView.isHidden = true
        settingsContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        let settingsStack = UIStackView()
        settingsStack.axis = .vertical
        settingsStack.spacing = 8
        settingsStack.translatesAutoresizingMaskIntoConstraints = false
        settingsContainerView.addSubview(settingsStack)
        NSLayoutConstraint.activate([
            settingsStack.topAnchor.constraint(equalTo: settingsContainerView.topAnchor, constant: 16),
            settingsStack.leadingAnchor.constraint(equalTo: settingsContainerView.leadingAnchor, constant: 16),
            settingsStack.trailingAnchor.constraint(equalTo: settingsContainerView.trailingAnchor, constant: -16),
            settingsStack.bottomAnchor.constraint(equalTo: settingsContainerView.bottomAnchor, constant: -16)
        ])
        
        let settingsTitle = UILabel()
        settingsTitle.text = "Settings"
        settingsTitle.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        settingsStack.addArrangedSubview(settingsTitle)
        
        let appIdLabel = UILabel()
        appIdLabel.text = "App ID"
        settingsStack.addArrangedSubview(appIdLabel)
        
        appIdTextField = UITextField()
        appIdTextField.borderStyle = .roundedRect
        appIdTextField.text = appId
        settingsStack.addArrangedSubview(appIdTextField)
        
        let appKeyLabel = UILabel()
        appKeyLabel.text = "App Key"
        settingsStack.addArrangedSubview(appKeyLabel)
        
        appKeyTextField = UITextField()
        appKeyTextField.borderStyle = .roundedRect
        appKeyTextField.text = appKey
        settingsStack.addArrangedSubview(appKeyTextField)
        
        let applyChangesButton = UIButton(type: .system)
        applyChangesButton.setTitle("Apply Changes", for: .normal)
        applyChangesButton.addTarget(self, action: #selector(applySettings), for: .touchUpInside)
        settingsStack.addArrangedSubview(applyChangesButton)
        
        buttonStackView.addArrangedSubview(settingsContainerView)
        
        // 기능 버튼들을 추가 (추가할 버튼은 기존 addFunctionButton 함수로 동일한 효과를 줌)
        func addFunctionButton(title: String, action: Selector) {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.layer.cornerRadius = 8
            button.backgroundColor = .systemBlue
            button.tintColor = .white
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            button.addTarget(self, action: action, for: .touchUpInside)
            buttonStackView.addArrangedSubview(button)
        }
        
        addFunctionButton(title: "Initialize", action: #selector(initializeTapped))
        addFunctionButton(title: "Check Initialization Status", action: #selector(checkInitStatusTapped))
        addFunctionButton(title: "loginWithEmail", action: #selector(loginWithEmailTapped))
        addFunctionButton(title: "loginWithOauthProvider(google)", action: #selector(loginWithGoogleTapped))
        addFunctionButton(title: "Get Current Wepin User", action: #selector(getCurrentWepinUserTapped))
        addFunctionButton(title: "Generate Auth Pin Block", action: #selector(generateAuthPinBlockTapped))
        addFunctionButton(title: "Generate Auth Pin Block with View", action: #selector(generateAuthPinBlockWithViewTapped))
        addFunctionButton(title: "Send Auth Request", action: #selector(sendAuthRequestTapped))
        addFunctionButton(title: "Send Register With AuthPinBlock Request", action: #selector(sendRegisterWithGenerateAuthRequestTapped))
        addFunctionButton(title: "Generate Register Pin Block", action: #selector(generateRegisterPinBlockTapped))
        addFunctionButton(title: "Generate Register Pin Block with View", action: #selector(generateRegisterPinBlockWithViewTapped))
        addFunctionButton(title: "Send Register Request", action: #selector(sendRegisterRequestTapped))
        addFunctionButton(title: "Generate Change Pin Block", action: #selector(generateChangePinBlockTapped))
        addFunctionButton(title: "Generate Change Pin Block with View", action: #selector(generateChangePinBlockWithViewTapped))
        addFunctionButton(title: "Send Change Pin Request", action: #selector(sendChangeRequestTapped))
        addFunctionButton(title: "Generate Auth OTP Block", action: #selector(generateAuthOTPBlockTapped))
        addFunctionButton(title: "Generate Auth OTP Block with View", action: #selector(generateAuthOTPBlockWithViewTapped))
        addFunctionButton(title: "Logout", action: #selector(logoutTapped))
        addFunctionButton(title: "Finalize", action: #selector(finalizeTapped))
        
        // ✅ ScrollView 추가 (하단)
        let textWrapperScrollView = UIScrollView()
        textWrapperScrollView.translatesAutoresizingMaskIntoConstraints = false
        textWrapperScrollView.layer.borderColor = UIColor.lightGray.cgColor
        textWrapperScrollView.layer.borderWidth = 1
        textWrapperScrollView.layer.cornerRadius = 8
        textWrapperScrollView.clipsToBounds = true
        bottomContainer.addSubview(textWrapperScrollView)

        // ✅ Label 추가
        statusLabel = UILabel()
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.textColor = .black
        statusLabel.text = "Status: Not Initialized"
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        textWrapperScrollView.addSubview(statusLabel)

        // ✅ AutoLayout 설정
        NSLayoutConstraint.activate([
            // ScrollView Constraints
            textWrapperScrollView.topAnchor.constraint(equalTo: bottomContainer.topAnchor, constant: 8),
            textWrapperScrollView.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 16),
            textWrapperScrollView.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -16),
            textWrapperScrollView.bottomAnchor.constraint(equalTo: bottomContainer.bottomAnchor, constant: -8),
            
            // Label Constraints (ScrollView Content)
            statusLabel.topAnchor.constraint(equalTo: textWrapperScrollView.topAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: textWrapperScrollView.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: textWrapperScrollView.trailingAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: textWrapperScrollView.bottomAnchor),
            statusLabel.widthAnchor.constraint(equalTo: textWrapperScrollView.widthAnchor)
        ])
    }
    
    @objc func applySettings() {
        // 텍스트필드의 값으로 설정값 갱신
        appId = appIdTextField.text ?? appId
        appKey = appKeyTextField.text ?? appKey
        let params = WepinPinParams(appId: appId, appKey: appKey)
        wepinPin = WepinPin(params)
        updateStatus("Settings Applied")
    }
    
    @objc func initializeTapped() {
        Task {
            guard let pin = wepinPin else {
                updateStatus("wepinLogin is nil. Apply settings first.")
                return
            }
//            let attributes = WepinWidgetAttribute(defaultLanguage: selectedLanguage, defaultCurrency: "USD")
            do {
                let result = try await pin.initialize(attributes: WepinPinAttributes(defaultLanguage: "ko", defaultCurrency: "KRW"))
                updateStatus(result ? "Initialized" : "Initialization Failed")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func checkInitStatusTapped() {
        // SDK 내 isInitialized 여부에 따라 상태 확인
        if let pin = wepinPin, pin.isInitialized() {
            updateStatus("WepinPin is Initialized")
        } else {
            updateStatus("Not Initialized")
        }
    }
    
    @objc func loginWithEmailTapped() {
        Task {
            guard let login = wepinPin?.login else {
                updateStatus("wepnLogin is nil")
                return
            }
            do {
                let params = WepinLoginWithEmailParams(email: "EMAIL", password: "PASSWORD")
                let result = try await login.loginWithEmailAndPassword(params: params)
                updateStatus("loginWithEmail: \(result)")
                wepinLogin(loginResult: result)
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func loginWithGoogleTapped() {
        loginWithOauthProvider(provider: "google")
    }
    
    @objc func loginWithAppleTapped() {
        loginWithOauthProvider(provider: "apple")
    }
    
    @objc func loginWithDiscordTapped() {
        loginWithOauthProvider(provider: "discord")
    }
    
    @objc func loginWithNaverTapped() {
        loginWithOauthProvider(provider: "naver")
    }
    
    @objc func loginWithFacebookTapped() {
        loginWithOauthProvider(provider: "facebook")
    }
    
    @objc func loginWithLineTapped() {
        loginWithOauthProvider(provider: "line")
    }
    
    @objc func loginWithKakaoTapped() {
        loginWithOauthProvider(provider: "kakao")
    }
    
    @objc func generateAuthPinBlockTapped() {
        Task {
            guard let pin = wepinPin else {
                updateStatus("wepinPin or login is nil")
                return
            }
            do {
                let result = try await pin.generateAuthPINBlock(count: 1)
                signAuthBlock = result
                updateStatus("\(String(describing: result))")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    @objc func generateRegisterPinBlockTapped() {
        Task {
            guard let pin = wepinPin else {
                updateStatus("wepinPin or login is nil")
                return
            }
            do {
                let result = try await pin.generateRegistrationPINBlock()
                registerAuthBlock = result
                updateStatus("\(String(describing: result))")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func generateChangePinBlockTapped() {
        Task {
            guard let pin = wepinPin else {
                updateStatus("wepinPin or login is nil")
                return
            }
            do {
                let result = try await pin.generateChangePINBlock()
                changePinBlock = result
                updateStatus("\(String(describing: result))")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func generateAuthOTPBlockTapped() {
        Task {
            guard let pin = wepinPin else {
                updateStatus("wepinPin or login is nil")
                return
            }
            do {
                let result = try await pin.generateAuthOTPCode(viewController: self)
                authOTPBlock = result
                updateStatus("\(String(describing: result))")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func generateAuthPinBlockWithViewTapped() {
        Task {
            guard let pin = wepinPin else {
                updateStatus("wepinPin or login is nil")
                return
            }
            do {
                let result = try await pin.generateAuthPINBlock(count: 1, viewController: self)
                signAuthBlock = result
                updateStatus("\(String(describing: result))")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    @objc func generateRegisterPinBlockWithViewTapped() {
        Task {
            guard let pin = wepinPin else {
                updateStatus("wepinPin or login is nil")
                return
            }
            do {
                let result = try await pin.generateRegistrationPINBlock(viewController: self)
                registerAuthBlock = result
                updateStatus("\(String(describing: result))")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func generateChangePinBlockWithViewTapped() {
        Task {
            guard let pin = wepinPin else {
                updateStatus("wepinPin or login is nil")
                return
            }
            do {
                let result = try await pin.generateChangePINBlock(viewController: self)
                changePinBlock = result
                updateStatus("\(String(describing: result))")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func generateAuthOTPBlockWithViewTapped() {
        Task {
            guard let pin = wepinPin else {
                updateStatus("wepinPin or login is nil")
                return
            }
            do {
                let result = try await pin.generateAuthOTPCode(viewController: self)
                authOTPBlock = result
                updateStatus("\(String(describing: result))")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func getCurrentWepinUserTapped() {
        Task {
            guard let pin = wepinPin, let login = pin.login else {
                updateStatus("wepnLogin is nil")
                return
            }
            do {
                let result = try await login.getCurrentWepinUser()
                updateStatus("getCurrentWepinUser: \(result)")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func logoutTapped() {
        Task {
            guard let pin = wepinPin, let login = pin.login else {
                updateStatus("wepinLogin is nil")
                return
            }
            do {
                let result = try await login.logoutWepin()
                updateStatus("\(result)")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }

    private func loginWithOauthProvider(provider: String) {
        Task {
            guard let pin = wepinPin, let login = pin.login else {
                updateStatus("wepinLogin is nil")
                return
            }
//            guard let params = providerInfos[provider] else {
//                updateStatus("provider info is not exist")
//                return
//            }
            do {
//                let initialized = try await login.initialize()
                if (!login.isInitialized()) {
                    updateStatus("login initialize failed")
                    return
                }
                let params = WepinLoginOauth2Params(provider: "google", clientId: "GOOGLE_CLIENT_ID")
                let result = try await login.loginWithOauthProvider(params: params, viewController: self)
                updateStatus("loginWithOauthProvider: \(result)")
                switch(result.type) {
                case WepinOauthTokenType.idToken:
                    self.loginWithIdToken(idToken: result.token)
                case WepinOauthTokenType.accessToken:
                    self.loginWithAccessToken(provider: provider, accessToken: result.token)
                }
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func loginWithIdToken(idToken: String) {
        Task {
            guard let pin = wepinPin, let login = pin.login else {
                updateStatus("wepinLogin is nil")
                return
            }
            let params = WepinLoginOauthIdTokenRequest(idToken: idToken)
            do {
                let result = try await login.loginWithIdToken(params: params)
                updateStatus("loginWithIdToken: \(result)")
                self.wepinLogin(loginResult: result)
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func loginWithAccessToken(provider: String, accessToken: String) {
        Task {
            guard let pin = wepinPin, let login = pin.login else {
                updateStatus("wepinLogin is nil")
                return
            }
            let params = WepinLoginOauthAccessTokenRequest(provider: provider, accessToken: accessToken)
            do {
                let result = try await login.loginWithAccessToken(params: params)
                updateStatus("loginWithAccessToken: \(result)")
                self.wepinLogin(loginResult: result)
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func wepinLogin(loginResult: WepinLoginResult) {
        Task {
            guard let pin = wepinPin, let login = pin.login else {
                updateStatus("wepinLogin is nil")
                return
            }
            do {
                let result = try await login.loginWepin(params: loginResult)
                updateStatus("wepinLogin: \(result)")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func finalizeTapped() {
        Task {
            guard let pin = wepinPin else {
                updateStatus("WepinWidget is nil.")
                return
            }
            pin.finalize()
            updateStatus("Finalized")
        }
    }
    
    @objc func sendRegisterRequestTapped() {
        guard let pinBlock = registerAuthBlock else {
            updateStatus("pin block is not exist")
            return
        }
        
        guard let network = network else {
            updateStatus("network is nil")
            return
        }
        
        guard let login = wepinPin?.login else {
            updateStatus("login is nil")
            return
        }
        
        Task {
            do {
                let wepinUser = try await login.getCurrentWepinUser()
                
                let registerRequest = RegisterRequest(
                    userId: wepinUser.userInfo!.userId,
                    loginStatus: (wepinUser.userStatus?.loginStatus.rawValue)!,
                    walletId: wepinUser.walletId,
                    UVD: pinBlock.uvd,
                    hint: pinBlock.hint
                )
                
                network.setAuthToken(accessToken: wepinUser.token!.access, refreshToken: wepinUser.token!.refresh)
                
                network.register(params: registerRequest) { result in
                    switch result {
                    case.success(let response):
                        self.updateStatus("Successfully registered: \(response)")
                    case .failure(let error):
                        self.updateStatus("Failed to register: \(error.localizedDescription)")
                    }
                }
            } catch {
                updateStatus("Error: \(error)")
            }
        }
    }
    
//    @objc func sendAuthOTPRequestTapped() {
//        guard let pinBlock = authOTPBlock else {
//            updateStatus("pin block is not exist")
//            return
//        }
//        
//        guard let network = network else {
//            updateStatus("network is nil")
//            return
//        }
//        
//        guard let login = wepinPin?.login else {
//            updateStatus("login is nil")
//            return
//        }
//        
//        Task {
//            do {
//                let wepinUser = try await login.getCurrentWepinUser()
//                
//                let registerRequest = RegisterRequest(
//                    userId: wepinUser.userInfo!.userId,
//                    loginStatus: (wepinUser.userStatus?.loginStatus.rawValue)!,
//                    walletId: wepinUser.walletId,
//                    UVD: pinBlock.uvdList.first,
//                    hint: nil
//                )
//                
//                network.setAuthToken(accessToken: wepinUser.token!.access, refreshToken: wepinUser.token!.refresh)
//                
//                network.register(params: registerRequest) { result in
//                    switch result {
//                    case.success(let response):
//                        self.updateStatus("Successfully registered: \(response)")
//                    case .failure(let error):
//                        self.updateStatus("Failed to register: \(error.localizedDescription)")
//                    }
//                }
//            } catch {
//                updateStatus("Error: \(error)")
//            }
//        }
//    }
    
    @objc func sendAuthRequestTapped() {
        guard let pinBlock = signAuthBlock else {
            updateStatus("pin block is not exist")
            return
        }
        
        guard let network = network else {
            updateStatus("network is nil")
            return
        }
        
        guard let login = wepinPin?.login else {
            updateStatus("login is nil")
            return
        }
        
        Task {
            do {
                let wepinUser = try await login.getCurrentWepinUser()
                
                _ = pinBlock.otp
                let uvdList = pinBlock.uvdList
                
                network.setAuthToken(accessToken: wepinUser.token!.access, refreshToken: wepinUser.token!.refresh)
                
                let getAccountListRequest = GetAccountListRequest(
                    walletId: wepinUser.walletId!, userId: wepinUser.userInfo!.userId, localeId: "1"
                )
                
                network.getAppAccountList(params: getAccountListRequest) { result in
                    switch result {
                    case.success(let response):
                        for account in response.accounts {
                            print("AccountID: \(account.accountId), Balance: \(account.balance)")
                        }
                        
                        let otpCode: OtpCode? = {
                            if let otp = pinBlock.otp {
                                return OtpCode(code: otp, recovery: false)
                            }
                            return nil
                        }()
                        
                        guard let accountId = response.accounts.first?.accountId else {
                            self.updateStatus("No account found")
                            return
                        }
                        Task {
                            for (index, uvd) in uvdList.enumerated() {
                                let signRequest = SignRequest(
                                    type: "msg_sign",
                                    userId: wepinUser.userInfo!.userId,
                                    walletId: wepinUser.walletId!,
                                    accountId: accountId,
                                    contract: nil,
                                    tokenId: nil,
                                    isNft: nil,
                                    pin: uvd,
                                    otpCode: otpCode,
                                    txData: ["data": "test123456\(index * 50)"]
                                )
                                
                                let signResponse = await network.sign(params: signRequest)
                                
                                switch signResponse {
                                case .success(let response):
                                    self.updateStatus("Result for UVD \(index + 1) / Signature Result: \(response.signatureResult ?? "No signature result")")
                                case .failure(let error):
                                    self.updateStatus("Failed to sign for UVD \(index + 1): \(error.localizedDescription)")
                                }
                            }
                        }
                    case .failure(let error):
                        self.updateStatus("Failed to fetch account list: \(error.localizedDescription)")
                    }
                }
            } catch {
                updateStatus("Error: \(error)")
            }
        }
    }
    
    @objc func sendRegisterWithGenerateAuthRequestTapped() {
        guard let pinBlock = signAuthBlock else {
            updateStatus("pin block is not exist")
            return
        }
        
        guard let network = network else {
            updateStatus("network is nil")
            return
        }
        
        guard let login = wepinPin?.login else {
            updateStatus("login is nil")
            return
        }
        
        Task {
            do {
                let wepinUser = try await login.getCurrentWepinUser()
                
                let registerRequest = RegisterRequest(
                    userId: wepinUser.userInfo!.userId,
                    loginStatus: (wepinUser.userStatus?.loginStatus.rawValue)!,
                    walletId: wepinUser.walletId,
                    UVD: pinBlock.uvdList.first,
                    hint: nil
                )
                
                network.setAuthToken(accessToken: wepinUser.token!.access, refreshToken: wepinUser.token!.refresh)
                
                network.register(params: registerRequest) { result in
                    switch result {
                    case.success(let response):
                        self.updateStatus("Successfully registered: \(response)")
                    case .failure(let error):
                        self.updateStatus("Failed to register: \(error.localizedDescription)")
                    }
                }
            } catch {
                updateStatus("Error: \(error)")
            }
        }
    }
    
    @objc func sendChangeRequestTapped() {
        guard let pinBlock = changePinBlock else {
            updateStatus("pin block is not exist")
            return
        }
        
        guard let network = network else {
            updateStatus("network is nil")
            return
        }
        
        guard let login = wepinPin?.login else {
            updateStatus("login is nil")
            return
        }
        
        Task {
            do {
                let wepinUser = try await login.getCurrentWepinUser()
                
                let otpCode: OtpCode? = {
                    if let otp = pinBlock.otp {
                        return OtpCode(code: otp, recovery: false)
                    }
                    return nil
                }()
                let changeParams = ChangePinRequest(
                    userId: wepinUser.userInfo!.userId,
                    walletId: wepinUser.walletId!,
                    UVD: pinBlock.uvd,
                    newUVD: pinBlock.newUVD,
                    hint: pinBlock.hint,
                    otpCode: otpCode
                )
                
                network.setAuthToken(accessToken: wepinUser.token!.access, refreshToken: wepinUser.token!.refresh)
                
                network.changePin(params: changeParams) { result in
                    switch result {
                    case.success(let response):
                        self.updateStatus("Successfully change pin: \(response)")
                    case .failure(let error):
                        self.updateStatus("Failed to change pin: \(error.localizedDescription)")
                    }
                }
            } catch {
                updateStatus("Error: \(error)")
            }
        }
    }
    
    func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

