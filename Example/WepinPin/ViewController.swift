
import UIKit
import WepinLogin
import WepinPin

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var labalResult: UILabel!
    @IBOutlet weak var tvResult: UITextView!
    
    let appKey: String = "Wepin-App-Key"
    let appId: String = "Wepin-App-ID"
    let privateKey: String = "Wepin-OAuth-Verification-Key"
    
    
    let googleClientId: String = "Google-Client-ID"
    let appleClientId: String = "Apple-Client-ID"
    let discordClientId: String = "Discord-Client-ID"
    let naverClientId: String = "Naver-Client-ID"
    
    
    var wepinLogin: WepinLogin? = nil
    var wepinPin: WepinPin? = nil
    var network: Network? = nil
    var wepinUser: WepinUser? = nil
    
    private var wepinLoginRes: WepinLoginResult? = nil
    let testList = ["login With LoginLibrary(google)",
                    "init PIN Pad Library",
                    "isInitialized",
                    "change Language",
                    "RegistrationPinBlock(Register)",
                    "AuthPinBlock(Register)",
                    "AuthPinBlock(Tx Sign)",
                    "AuthPinBlock(Multi Tx Sign)",
                    "ChangePinBlock(Chang PIN)",
                    "AuthOTP",
                    "finalize"]

    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        
        let initParam = WepinLoginParams(appId: appId, appKey: appKey)
        let initPinParam = WepinPinParams(appId: appId, appKey: appKey)
        wepinLogin = WepinLogin(initParam)
        wepinPin = WepinPin(initPinParam)
        network = Network(appKey: appKey)
        
    }

    func testMethod(at indexPath: IndexPath){
        self.tvResult.text = String("processing...")
        switch testList[indexPath.row] {
            
        case "login With LoginLibrary(google)":
            do {
                print("login With LoginLibrary(google)")
                Task {
                    do {
                        guard let initResult = try await wepinLogin!.initialize() else {
                            self.tvResult.text = "LoginLib initResult returned nil."
                            return
                        }
                        
                        if !initResult {
                            self.tvResult.text = "LoginLib Init failed"
                            return
                        }
                        
                        let oauthParams = WepinLoginOauth2Params(provider: "google", clientId: self.googleClientId)
                        let res = try await wepinLogin!.loginWithOauthProvider(params: oauthParams, viewController: self)
                        let sign = wepinLogin!.getSignForLogin(privateKey: privateKey, message: res.token)
                        let params = WepinLoginOauthIdTokenRequest(idToken: res.token, sign: sign!)
                        wepinLoginRes = try await wepinLogin!.loginWithIdToken(params: params)
                        if(wepinLoginRes == nil) {
                            self.tvResult.text = String("Faild: Before performing the 'loginWepin' method, the 'loginWithToken', 'loginWithAccessToken', 'loginWithOauth', and 'loginWithEmailAndPassword' methods must be performed first.")
                            return
                        }
                        wepinUser = try await wepinLogin!.loginWepin(params: wepinLoginRes!)
                        wepinLoginRes = nil
                        self.tvResult.text = String("Successed: \(wepinUser)")
                        
                    } catch (let error){
                        self.tvResult.text = String("Faild: \(error)")
                    }
                }
            }
            
        case "init PIN Pad Library":
            do {
                print("init PIN Pad Library")
                Task {
                    do {
                        let attributes = WepinPinAttributes(language: "en")
                        if let res = try await wepinPin?.initialize(attributes: attributes) {
                            self.tvResult.text = "Successed: \(res)"
                        } else {
                            self.tvResult.text = "Failed: No result returned from initialization"
                        }
                    } catch {
                        self.tvResult.text = "Failed: \(error)"
                    }
                }
            }
            
        case "isInitialized":
            print("isInitialized")
            let result = wepinPin!.isInitialized()
            self.tvResult.text = String("result - \(result)")
        case "change Language":
            do {
                print("change Language")
                wepinPin!.changeLanguage(language: "ko")
                self.tvResult.text = String("Change Language to ko")
            }

        case "RegistrationPinBlock(Register)":
            print("RegistrationPinBlock(Register)")
            // loginStatus가 pinRequired 인 경우 실행
            if wepinUser == nil {
                print("wepinUser is nil")
                DispatchQueue.main.async {
                    self.tvResult.text = "wepinUser is nil"
                }
                return // 종료
            }
            // 비동기 작업 시작
            Task {
                do {
                    // Registration PIN Block 생성
                    let registrationPinBlock = try await wepinPin!.generateRegistrationPINBlock()
                    
                    if let registerPinBlock = registrationPinBlock {
                        print("Registration PIN Block successfully generated")
                        
                        // UI 업데이트는 메인 스레드에서 수행
                        DispatchQueue.main.async {
                            self.tvResult.text = "Registration PIN Block: \(registerPinBlock.toJson())"
                        }
                        
                        // AuthToken 설정
                        network!.setAuthToken(accessToken: wepinUser!.token!.access, refreshToken: wepinUser!.token!.refresh)
                        // RegisterRequest 생성

                        let registerRequest = RegisterRequest(
                          userId: wepinUser!.userInfo!.userId,
                          loginStatus: (wepinUser!.userStatus?.loginStatus.rawValue)!,
                          walletId: wepinUser!.walletId,
                          UVD: registerPinBlock.uvd,
                          hint: registerPinBlock.hint
                        )
                        
                        // register 호출
                        network!.register(params: registerRequest) { result in
                            switch result {
                            case .success(let response):
                                print("Successfully registered:")
                                DispatchQueue.main.async {
                                    self.tvResult.text = "Registration Successful: \(response)"
                                }
                            case .failure(let error):
                                print("Failed to register: \(error.localizedDescription)")
                                DispatchQueue.main.async {
                                    self.tvResult.text = "Registration Failed: \(error.localizedDescription)"
                                }
                            }
                        }
                        
                    } else {
                        print("Failed to generate Registration PIN Block")
                        DispatchQueue.main.async {
                            self.tvResult.text = "Failed to generate Registration PIN Block"
                        }
                    }
                } catch {
                    print("Error occurred while generating Registration PIN Block: \(error)")
                    DispatchQueue.main.async {
                        self.tvResult.text = "Error occurred while generating Registration PIN Block: \(error)"
                    }
                }
            }


        case"AuthPinBlock(Register)":
            // loginStatus가 registerRequired 인 경우 실행
            if wepinUser == nil {
                print("wepinUser is nil")
                DispatchQueue.main.async {
                    self.tvResult.text = "wepinUser is nil"
                }
                return // 종료
            }
            do {
                print("AuthPinBlock(Register)")
                Task {
                     do {
                         // count 값을 전달하여 generateAuthPINBlock 호출
                         let count = 1
                         let authPinBlock = try await self.wepinPin!.generateAuthPINBlock(count: count)
                          // 응답값 처리
                          if let authPinBlock = authPinBlock {
                              print("Received AuthPinBlock: \(authPinBlock)")
                              
                              // AuthToken 설정
                              network!.setAuthToken(accessToken: wepinUser!.token!.access, refreshToken: wepinUser!.token!.refresh)
                              
                              // RegisterRequest 요청 객체 생성
                              let registerRequest = RegisterRequest(
                                userId: wepinUser!.userInfo!.userId,
                                loginStatus: (wepinUser!.userStatus?.loginStatus.rawValue)!,
                                walletId: wepinUser!.walletId,
                                UVD: authPinBlock.uvdList.first,
                                hint: nil
                              )
  
                              // register 호출
                              network!.register(params: registerRequest) { result in
                                  switch result {
                                  case .success(let response):
                                      print("Successfully registered:")
                                      DispatchQueue.main.async {
                                          self.tvResult.text = "Registration Successful: \(response)"
                                      }
                                  case .failure(let error):
                                      print("Failed to register: \(error.localizedDescription)")
                                      DispatchQueue.main.async {
                                          self.tvResult.text = "Registration Failed: \(error.localizedDescription)"
                                      }
                                  }
                              }
                              
                          } else {
                              print("AuthPinBlock is nil")
                              DispatchQueue.main.async {
                                  self.tvResult.text = "AuthPinBlock is nil"
                              }
                          }
                        
                     } catch {
                         // 에러 처리
                         print("Failed to generate Auth PIN block: \(error)")
                         DispatchQueue.main.async {
                             self.tvResult.text = "Failed to generate Auth PIN block: \(error)"
                         }
                     }
                 }
            }

        case "AuthPinBlock(Tx Sign)":
            // wepinUser가 nil  경우 종료
            if wepinUser == nil {
                print("wepinUser is nil")
                DispatchQueue.main.async {
                    self.tvResult.text = "wepinUser is nil"
                }
                return // 종료
            }
            Task {
                do {
                    print("AuthPinBlock(Tx Sign)")

                    // count 값을 전달하여 generateAuthPINBlock 호출
                    let count = 1
                    let authPinBlock = try await self.wepinPin!.generateAuthPINBlock(count: count)

                    // authPinBlock이 nil이 아닌 경우 처리
                    guard let authPinBlock = authPinBlock else {
                        print("AuthPinBlock is nil")
                        DispatchQueue.main.async {
                            self.tvResult.text = "AuthPinBlock is nil"
                        }
                        return
                    }

                    print("Received AuthPinBlock: \(authPinBlock)")

                    
                    let otp = authPinBlock.otp
                    let uvdList = authPinBlock.uvdList
                    // AuthToken 설정
                    network!.setAuthToken(accessToken: wepinUser!.token!.access, refreshToken: wepinUser!.token!.refresh)

                    // 계정 목록 요청
                    let getAccountListRequest = GetAccountListRequest(
                        walletId: wepinUser!.walletId!,
                        userId: wepinUser!.userInfo!.userId,
                        localeId: "1"
                    )

                    // getAppAccountList 호출
                    network!.getAppAccountList(params: getAccountListRequest) { result in
                        switch result {
                        case .success(let response):
                            print("Successfully fetched account list:")
                            //print("Wallet ID: \(response.walletId)")
                            for account in response.accounts {
                                print("Account ID: \(account.accountId), Balance: \(account.balance)")
                            }

                            // OTP 코드 설정
                            let otpCode: OtpCode? = {
                                if let otp = authPinBlock.otp {
                                    return OtpCode(code: otp, recovery: false)
                                }
                                return nil
                            }()

                            // accountId를 network response의 첫 번째 account로 설정
                            guard let accountId = response.accounts.first?.accountId else {
                                print("No account found")
                                DispatchQueue.main.async {
                                    self.tvResult.text = "No account found"
                                }
                                return
                            }

                            // uvdList의 각 UVD에 대해 서명 요청 수행
                            Task {
                                for (index, uvd) in uvdList.enumerated() {
                                    //print("Processing UVD \(index + 1) of \(uvdList.count)")

                                    // 서명 요청 객체 생성
                                    let signRequest = SignRequest(
                                        type: "msg_sign",
                                        userId: self.wepinUser!.userInfo!.userId,
                                        walletId: self.wepinUser!.walletId!,
                                        accountId: accountId,
                                        contract: nil,
                                        tokenId: nil,
                                        isNft: nil,
                                        pin: uvd, // uvdList에서 순차적으로 가져옴
                                        otpCode: otpCode,
                                        txData: ["data": "test123456\(index * 50)"]  // 필요한 txData
                                    )

                                    // 서명 요청 수행
                                    let signResponse = await self.network!.sign(params: signRequest)

                                    switch signResponse {
                                    case .success(let response):
                                        //print("Successfully signed for UVD \(index + 1):")
                                        print("Signature Result: \(response.signatureResult ?? "No signature result")")
                                        DispatchQueue.main.async {
                                            self.tvResult.text = String(format: "Result for UVD %d: %@", index + 1, response.signatureResult ?? "No signature result")
                                        }

                                    case .failure(let error):
                                        print("Failed to sign for UVD \(index + 1): \(error.localizedDescription)")
                                        DispatchQueue.main.async {
                                            self.tvResult.text = String(format: "Failed to sign for UVD %d: %@", index + 1, error.localizedDescription)
                                        }
                                    }
                                }
                            }

                        case .failure(let error):
                            print("Failed to fetch account list. Error: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                self.tvResult.text = "Failed to fetch account list. Error: \(error.localizedDescription)"
                            }
                        }
                    }

                } catch {
                    // 에러 처리
                    print("Failed to generate Auth PIN block: \(error)")
                    DispatchQueue.main.async {
                        self.tvResult.text = "Failed to generate Auth PIN block: \(error)"
                    }
                }
            }
            
        case "AuthPinBlock(Multi Tx Sign)":
            // wepinUser가 nil  경우 종료
            if wepinUser == nil {
                print("wepinUser is nil")
                DispatchQueue.main.async {
                    self.tvResult.text = "wepinUser is nil"
                }
                return // 종료
            }
            
            Task {
                do {
                    print("AuthPinBlock(Multi Tx Sign)")

                    // count 값을 전달하여 generateAuthPINBlock 호출
                    let count = 3
                    let authPinBlock = try await self.wepinPin!.generateAuthPINBlock(count: count)

                    // authPinBlock이 nil이 아닌 경우 처리
                    guard let authPinBlock = authPinBlock else {
                        DispatchQueue.main.async {
                            self.tvResult.text = "AuthPinBlock is nil"
                        }
                        return
                    }

                    print("Received AuthPinBlock: \(authPinBlock)")

                    // OTP 및 UVD 목록 출력
                    let otp = authPinBlock.otp
                    let uvdList = authPinBlock.uvdList
                    print("OTP: \(otp ?? "nil")")
                    for uvd in uvdList {
                        print("UVD - b64SKey: \(uvd.b64SKey), b64Data: \(uvd.b64Data)")
                    }

                    // AuthToken 설정
                    network!.setAuthToken(accessToken: wepinUser!.token!.access, refreshToken: wepinUser!.token!.refresh)

                    // 계정 목록 요청
                    let getAccountListRequest = GetAccountListRequest(
                        walletId: wepinUser!.walletId!,
                        userId: wepinUser!.userInfo!.userId,
                        localeId: "1"
                    )

                    // getAppAccountList 호출
                    network!.getAppAccountList(params: getAccountListRequest) { result in
                        switch result {
                        case .success(let response):
                            print("Successfully fetched account list:")
                            //print("Wallet ID: \(response.walletId)")
                            for account in response.accounts {
                                print("Account ID: \(account.accountId), Balance: \(account.balance)")
                            }

                            // OTP 코드 설정
                            let otpCode: OtpCode? = {
                                if let otp = authPinBlock.otp {
                                    return OtpCode(code: otp, recovery: false)
                                }
                                return nil
                            }()

                            // accountId를 network response의 첫 번째 account로 설정
                            guard let accountId = response.accounts.first?.accountId else {
                                print("No account found")
                                DispatchQueue.main.async {
                                    self.tvResult.text = "No account found"
                                }
                                return
                            }

                            // uvdList의 각 UVD에 대해 서명 요청 수행
                            Task {
                                for (index, uvd) in uvdList.enumerated() {
                                    print("Processing UVD \(index + 1) of \(uvdList.count)")

                                    // 서명 요청 객체 생성
                                    let signRequest = SignRequest(
                                        type: "msg_sign",
                                        userId: self.wepinUser!.userInfo!.userId,
                                        walletId: self.wepinUser!.walletId!,
                                        accountId: accountId,
                                        contract: nil,
                                        tokenId: nil,
                                        isNft: nil,
                                        pin: uvd, // uvdList에서 순차적으로 가져옴
                                        otpCode: otpCode,
                                        txData: ["data": "test123456\(index * 50)"]  // 필요한 txData
                                    )

                                    // 서명 요청 수행
                                    let signResponse = await self.network!.sign(params: signRequest)

                                    switch signResponse {
                                    case .success(let response):
                                        print("Signature Result: \(response.signatureResult ?? "No signature result")")
                                        DispatchQueue.main.async {
                                            self.tvResult.text = String(format: "Result for UVD %d: %@", index + 1, response.signatureResult ?? "No signature result")
                                        }

                                    case .failure(let error):
                                        print("Failed to sign for UVD \(index + 1): \(error.localizedDescription)")
                                        DispatchQueue.main.async {
                                            self.tvResult.text = String(format: "Failed to sign for UVD %d: %@", index + 1, error.localizedDescription)
                                        }
                                    }
                                }
                            }

                        case .failure(let error):
                            print("Failed to fetch account list. Error: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                self.tvResult.text = "Failed to fetch account list. Error: \(error.localizedDescription)"
                            }
                        }
                    }

                } catch {
                    // 에러 처리
                    print("Failed to generate Auth PIN block: \(error)")
                    DispatchQueue.main.async {
                        self.tvResult.text = "Failed to generate Auth PIN block: \(error)"
                    }
                }
            }
            
        case "ChangePinBlock(Chang PIN)":
            // wepinUser가 nil  경우 종료
            if wepinUser == nil {
                print("wepinUser is nil")
                DispatchQueue.main.async {
                    self.tvResult.text = "wepinUser is nil"
                }
                return // 종료
            }
            
            do {
                print("ChangePinBlock(Chang PIN)")
                Task {
                     do {

                         let changePinBlock = try await self.wepinPin!.generateChangePINBlock()
                          // 응답값 처리
                          if let changePinBlock = changePinBlock {
                              //print("Received changePinBlock: \(changePinBlock)")
                              
                              // OTP 코드 설정
                              let otpCode: OtpCode? = {
                                  if let otp = changePinBlock.otp {
                                      return OtpCode(code: otp, recovery: false)
                                  }
                                  return nil
                              }()
                              
                              // AuthToken 설정
                              network!.setAuthToken(accessToken: wepinUser!.token!.access, refreshToken: wepinUser!.token!.refresh)
                              
                              // RegisterRequest 요청 객체 생성
                              let changePinRequest = ChangePinRequest(
                                userId: wepinUser!.userInfo!.userId,
                                walletId: wepinUser!.walletId!,
                                UVD: changePinBlock.uvd,
                                newUVD: changePinBlock.newUVD,
                                hint: changePinBlock.hint,
                                otpCode: otpCode
                              )
  
                              // register 호출
                              network!.changePin(params: changePinRequest) { result in
                                  switch result {
                                  case .success(let response):
                                      print("Successfully changePin")
                                      DispatchQueue.main.async {
                                          self.tvResult.text = "changePin Successful: \(response)"
                                      }
                                  case .failure(let error):
                                      print("Failed to changePin: \(error.localizedDescription)")
                                      DispatchQueue.main.async {
                                          self.tvResult.text = "changePin Failed: \(error.localizedDescription)"
                                      }
                                  }
                              }
                              
                          } else {
                              print("ChangePinBlock is nil")
                              DispatchQueue.main.async {
                                  self.tvResult.text = "ChangePinBlock is nil"
                              }
                          }
                        
                     } catch {
                         // 에러 처리
                         print("Failed to generate Auth PIN block: \(error)")
                         DispatchQueue.main.async {
                             self.tvResult.text = "Failed to generate Auth PIN block: \(error)"
                         }
                     }
                 }
            }

        case "AuthOTP":
            do {
                print("AuthOTP")
                Task {
                     do {
                         let authOTPCode = try await self.wepinPin!.generateAuthOTPCode()
                          // 응답값 처리
                          if let authOTPCode = authOTPCode {
                              print("Received authOTPCode: \(authOTPCode)")
                              
                              DispatchQueue.main.async {
                                  self.tvResult.text = "Received authOTPCode: \(authOTPCode.code)"
                              }
                          } else {
                              print("AuthOTP is nil")
                              DispatchQueue.main.async {
                                  self.tvResult.text = "AuthOTP is nil"
                              }
                          }
                        
                     } catch {
                         // 에러 처리
                         print("Failed to generate AuthOTP: \(error)")
                         DispatchQueue.main.async {
                             self.tvResult.text = "Failed to generate AuthOTP: \(error)"
                         }
                     }
                 }
            }
        case "finalize":
            do {
                print("finalize")
                wepinPin!.finalize()
                wepinLogin!.finalize()
                self.tvResult.text = String("Successed")
            }
        default:
            print("Unknown test menu")
            DispatchQueue.main.async {
                self.tvResult.text = "Unknown test menu"
            }
        }
    }
    
}
extension ViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print("Cell at \(indexPath.row) selected")
        testMethod(at: indexPath)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return testList.count

    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "testCell", for: indexPath) as! TestListCellTableViewCell
        cell.listLabel.text = testList[indexPath.row]
        
        return cell

    }

}
