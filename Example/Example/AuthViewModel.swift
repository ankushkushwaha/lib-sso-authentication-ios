//
//  AuthViewModel.swift
//  DemoProject
//
//  Created by Ankush Kushwaha on 21/01/25.
//


import SwiftUI
import lib_sso_authentication_ios
import AppAuth

class AuthViewModel: ObservableObject {
    @Published var accessToken: String?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isPresentedLogin = false
    @Published var isPresentedLogout = false

    private let clientId = "b453a24f-79c5-45a2-b567-da7244a9af4e"
    private let issuerUrl = "https://soleranab2bnprd.b2clogin.com/SoleraNAB2BNPrd.onmicrosoft.com/b2c_1a_hrdsignin_v2/v2.0"
    private let redirectUri = "com.roadnet.mobile.fleetview://oauth2redirect"
    private let authorizationEndpoint = "https://soleranab2bnprd.b2clogin.com/SoleraNAB2BNPrd.onmicrosoft.com/b2c_1a_hrdsignin_v2/oauth2/v2.0/authorize"
    private let tokenEndpoint = "https://soleranab2bnprd.b2clogin.com/SoleraNAB2BNPrd.onmicrosoft.com/b2c_1a_hrdsignin_v2/oauth2/v2.0/token"
    private let logoutUrl = "https://soleranab2bnprd.b2clogin.com/SoleraNAB2BNPrd.onmicrosoft.com/b2c_1a_hrdsignin_v2/oauth2/v2.0/logout"
    
    init(accessToken: String? = nil, errorMessage: String? = nil, isLoading: Bool = false, isPresentedLogin: Bool = false, isPresentedLogout: Bool = false) {
        
        SSOAuthentication.initialize(
            clientId: clientId,
            issuerUrl: issuerUrl,
            redirectUri: redirectUri,
            postLogoutRedirectUri: redirectUri,
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint,
            logoutUrl: logoutUrl,
            scope: [clientId, OIDScopeOpenID, OIDScopeProfile, "offline_access"]
        )
        
        self.accessToken = SSOAuthentication.shared.accessToken
        self.errorMessage = errorMessage
        self.isLoading = isLoading
        self.isPresentedLogin = isPresentedLogin
        self.isPresentedLogout = isPresentedLogout
    }
    
    func login(from viewController: UIViewController) {
                
        isLoading = true
        
        isPresentedLogin = true
                
        SSOAuthentication.shared.startAuthenticationProcess(from: viewController, username: "ommstdqaeuser1@mail.com", completion: { [weak self] accessToken, error in
            
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                self?.accessToken = SSOAuthentication.shared.accessToken

                self?.isPresentedLogin = false
            }
        }) 
    }
    
    func logout(viewController: UIViewController) {
        if SSOAuthentication.shared.accessToken == nil {
            return
        }
        
        isPresentedLogout = true

        SSOAuthentication.shared.logout(viewController: viewController) {
            [weak self] endSessionResponse, error in
            
            self?.isPresentedLogout = false
            
            self?.accessToken = SSOAuthentication.shared.accessToken
        }
    }
    
}
