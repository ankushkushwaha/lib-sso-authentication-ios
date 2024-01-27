//
//  AppAuthManager.swift
//  lib-sso-authentication-ios
//
//  Created by Ankush Kushwaha on 21/01/25.
//


import Foundation
import AppAuth

public class AppAuthManager {
    nonisolated(unsafe) public static let shared = AppAuthManager()
    
    private var userAgentSession: OIDExternalUserAgentSession?
    private var authState: OIDAuthState?
    private var authStateService = AuthStateService()
    private init() {}
    
    public func authorize(
        from viewController: UIViewController,
        clientId: String,
        redirectUri: String,
        authorizationEndpoint: String,
        tokenEndpoint: String,
        completion: @escaping (String?, Error?) -> Void
    ) {
        guard let authEndpoint = URL(string: authorizationEndpoint),
              let tokenEndpoint = URL(string: tokenEndpoint),
              let redirectUri = URL(string: redirectUri) else {
            completion(nil, NSError(domain: "AppAuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let config = OIDServiceConfiguration(authorizationEndpoint: authEndpoint, tokenEndpoint: tokenEndpoint)
        
        let request = OIDAuthorizationRequest(
            configuration: config,
            clientId: clientId,
            clientSecret: nil,
            scopes: [clientId, OIDScopeOpenID, OIDScopeProfile, "offline_access"],
            redirectURL: redirectUri,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil
        )
        
        userAgentSession = OIDAuthState.authState(
            byPresenting: request,
            presenting: viewController
        ) { [weak self] authState, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let authState = authState else {
                completion(nil, NSError(domain: "AppAuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Authorization failed"]))
                return
            }
            
            self?.authState = authState
            let accessToken = authState.lastTokenResponse?.accessToken
            
            self?.authStateService.saveAuthState(authState)
            
            completion(accessToken, nil)
        }
    }
    
    
    //    private func fetchDiscoveryConfig(completion: @escaping ((OIDServiceConfiguration?,
    //                                                              Error?) -> Void)) {
    //        guard let issuer = URL(string: config.issuer) else {
    //            return
    //        }
    //
    //        AnalyticsManager.sharedInstance.trackData(name: AnalyticsManager.events.SSO_FETCH_DISCOVER_CONFIGURATION)
    //
    //        // discovers endpoints
    //        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) {
    //
    //            configuration, error in
    //
    //            if error != nil {
    //                AnalyticsManager.sharedInstance.trackData(name: AnalyticsManager.events.SSO_FETCH_DISCOVER_CONFIGURATION_FAILURE)
    //
    //                completion(nil, error)
    //
    //                return
    //            }
    //
    //            AnalyticsManager.sharedInstance.trackData(name: AnalyticsManager.events.SSO_FETCH_DISCOVER_CONFIGURATION_SUCCESS)
    //
    //            completion(configuration, nil)
    //        }
    //    }
    
    public func logout(redirectUrl: String,
                       viewController: UIViewController,
                       completion: @escaping ((OIDEndSessionResponse?, Error?) -> Void)) {
        
        
        guard let savedAuthState = authStateService.getAuthState(),
              let idToken = savedAuthState.lastTokenResponse?.idToken else {
            completion(nil, nil)
           return
        }
        
        guard let redirectUrl = URL(string: redirectUrl) else {
            completion(nil, nil)
          return
        }
        
        let configuration = savedAuthState.lastAuthorizationResponse.request.configuration
        
        let endSessionRequest = OIDEndSessionRequest(
            configuration: configuration,
            idTokenHint: idToken,
            postLogoutRedirectURL: redirectUrl,
            additionalParameters: nil)
        
        
        guard #available(iOS 13, *) else {
            print("This feature requires iOS 13 or later.")
            completion(nil, nil)
            return
        }
            
        guard let agent = OIDExternalUserAgentIOS(presenting: viewController,
                                                      prefersEphemeralSession: true) else {
                return
            }
        
       
        userAgentSession = OIDAuthorizationService.present(
            endSessionRequest,
            externalUserAgent: agent) { [weak self] response, error in
                completion(response, error)
            }
    }

}
