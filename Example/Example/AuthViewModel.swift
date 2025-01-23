//
//  AuthViewModel.swift
//  DemoProject
//
//  Created by Ankush Kushwaha on 21/01/25.
//


import SwiftUI
import lib_sso_authentication_ios

class AuthViewModel: ObservableObject {
    @Published var accessToken: String?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isPresented = false

    func login(from viewController: UIViewController) {
        let clientId = "b453a24f-79c5-45a2-b567-da7244a9af4e"
        let redirectUri = "com.roadnet.mobile.fleetview://oauth2redirect/"
        let authorizationEndpoint = "https://soleranab2bnprd.b2clogin.com/SoleraNAB2BNPrd.onmicrosoft.com/b2c_1a_hrdsignin_v2/oauth2/v2.0/authorize"
        let tokenEndpoint = "https://soleranab2bnprd.b2clogin.com/SoleraNAB2BNPrd.onmicrosoft.com/b2c_1a_hrdsignin_v2/oauth2/v2.0/token"

        isLoading = true
        
        isPresented = true
        AppAuthManager.shared.authorize(
            from: viewController,
            clientId: clientId,
            redirectUri: redirectUri,
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint
        ) { [weak self] accessToken, error in
            
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }

                self?.accessToken = accessToken
                
                self?.isPresented = false
            }
        }
    }
}
