//
//  AppAuthManager.swift
//  lib-sso-authentication-ios
//
//  Created by Ankush Kushwaha on 21/01/25.
//


import Foundation
import AppAuth

public class SSOAuthentication {
    
    private var userAgentSession: OIDExternalUserAgentSession?
    private var authState: OIDAuthState?
    private var config: SSOConfig
    private var stateHandler = AuthStateService()
    
    public nonisolated(unsafe) static var shared: SSOAuthentication!
    
    public static func initialize(
        clientId: String,
        issuerUrl: String,
        redirectUri: String,
        postLogoutRedirectUri: String,
        authorizationEndpoint: String,
        tokenEndpoint: String,
        logoutUrl: String,
        scope: [String]
    ) {
        guard shared == nil else {
#if DEBUG
            print("Warning: SSOAuthentication has already been initialized!")
#endif
            return
        }
        shared = SSOAuthentication(
            clientId: clientId,
            issuerUrl: issuerUrl,
            redirectUri: redirectUri,
            postLogoutRedirectUri: postLogoutRedirectUri,
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint,
            logoutUrl: logoutUrl,
            scope: scope
        )
        
    }
    
    private init(
        clientId: String,
        issuerUrl: String,
        redirectUri: String,
        postLogoutRedirectUri: String,
        authorizationEndpoint: String,
        tokenEndpoint: String,
        logoutUrl: String,
        scope: [String]
    ) {
        
        self.config = SSOConfig(
            issuer: issuerUrl,
            clientID: clientId,
            redirectUri: redirectUri + "/",
            postLogoutRedirectUri: postLogoutRedirectUri,
            scope: scope,
            autherizationUrl: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint,
            logoutUrl: logoutUrl + "/"
        )
    }
    
    public var accessToken: String? {
        stateHandler.savedAuthState?.lastTokenResponse?.accessToken
    }
    
    public func startAuthenticationProcess(
        from viewController: UIViewController,
        username: String?,
        completion: @escaping (String?, SSOError?) -> Void
    ) {
        
        fetchDiscoveryConfig { fetchedConfig, error in
            
            var configuration: OIDServiceConfiguration? = fetchedConfig
            
            if fetchedConfig == nil {
                // Inject config manually, if discovery url failed
                
                guard let authorizationEndpoint = URL(string: self.config.autherizationUrl),
                      let tokenEndpoint = URL(string: self.config.tokenEndpoint),
                      let logoutUrl = URL(string: self.config.logoutUrl) else {
#if DEBUG
                    print("SSO cofiguration is missing.")
#endif
                    return
                }
                
                configuration = OIDServiceConfiguration(
                    authorizationEndpoint: authorizationEndpoint,
                    tokenEndpoint: tokenEndpoint,
                    issuer: nil,
                    registrationEndpoint: nil,
                    endSessionEndpoint: logoutUrl
                )
            }
            
            guard let configuration = configuration else {
                completion(nil, error as? SSOAuthentication.SSOError)
                return
            }
            
            // Step 2: Start login
            
            self.startLogin(username: username,
                            configuration: configuration,
                            viewController: viewController) {
                accessToken, error in
                
                completion(accessToken, error)
                
                return
            }
        }
    }
    
    private func startLogin(username: String?,
                            configuration: OIDServiceConfiguration,
                            viewController: UIViewController,
                            completion: @escaping ((String?,
                                                    SSOAuthentication.SSOError?) -> Void)) {
        
        guard let redirectUri = URL(string: config.redirectUri) else {
            return
        }
        
        var hint: [String: String]? = nil
        if let username {
            hint = [AppAuthConstants.ssoLoginHint: username]
        }
        
        let request = OIDAuthorizationRequest(
            configuration: configuration,
            clientId: self.config.clientID,
            clientSecret: nil,
            scopes: self.config.scope,
            redirectURL: redirectUri,
            responseType: OIDResponseTypeCode,
            additionalParameters: hint
        )
        
        userAgentSession = OIDAuthState.authState(byPresenting: request, presenting: viewController, prefersEphemeralSession: true) { authState, error in
            
            if let authState = authState {
                
                self.stateHandler.setAuthState(authState)
                
                let response = authState.lastTokenResponse
                
                if let accessToken = response?.accessToken {
                    completion(response?.accessToken, nil)
                } else {
                    completion(nil, SSOError.errorWithDescription("No acces_token fetched. Please check your configuration and scopes.") )

                }
                
#if DEBUG
                print("\n*** ACCESS_TOKEN ****\n")
                
                print(response?.accessToken ?? "ACCESS_TOKEN is not available")
                
                print("\n*** REFRESH_TOKEN ****\n")
                
                print(response?.refreshToken ?? "REFRESH_TOKEN is not available")
                
                print("\n*** ID_TOKEN ****\n")
                
                print(response?.idToken ?? "ID_TOKEN is not available")
#endif
                
            } else {
                
                // handle error
                if let errorCode = (error as? NSError)?.code,
                   let oidErrorCode = OIDErrorCode(rawValue: errorCode) {
                    
                    let ssoError = SSOError(errorCode: oidErrorCode, error)
                    
                    completion(nil, ssoError)
                    
                    return
                }
                
                completion(nil, SSOError.unknownError(error))
            }
        }
    }
    
    private func fetchDiscoveryConfig(
        completion: @escaping ((OIDServiceConfiguration?, Error?) -> Void)) {
            
            guard let issuer = URL(string: config.issuer) else {
                return
            }
            
            // discovers endpoints
            OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) {
                
                configuration, error in
                
                if error != nil {
                    completion(nil, error)
                    return
                }
                completion(configuration, nil)
            }
        }
    
    public func logout(viewController: UIViewController,
                       completion: @escaping ((Bool, SSOError?) -> Void)) {
        
        guard let configuration = stateHandler.savedAuthState?.lastAuthorizationResponse.request.configuration,
              let idToken = stateHandler.savedAuthState?.lastTokenResponse?.idToken,
              let redirectUrl = URL(string: self.config.redirectUri) else {
            return
        }
        
        let endSessionRequest = OIDEndSessionRequest(
            configuration: configuration,
            idTokenHint: idToken,
            postLogoutRedirectURL: redirectUrl,
            additionalParameters: nil)
        
        guard let agent = OIDExternalUserAgentIOS(presenting: viewController,
                                                  prefersEphemeralSession: true) else {
            return
        }
        
        userAgentSession = OIDAuthorizationService.present(
            endSessionRequest,
            externalUserAgent: agent) { [weak self] response, error in
                guard let `self` = self else { return }
                
                if let error = error,
                   let errorCode = (error as? NSError)?.code,
                   let oidErrorCode = OIDErrorCode(rawValue: errorCode) {
                    
                    // If browser is dismissed by user
                    
                    let ssoError = SSOError(errorCode: oidErrorCode, error)
                    
                    // Logout user anyway, if browser dismisssed by user
                    self.stateHandler.setAuthState(nil)
                    completion(true, ssoError)
                    
                    return
                }
                
                if let error = error {
                    
                    completion(false, SSOError.unknownError(error))
                    return
                }
                
                guard let response = response else {
#if DEBUG
                    print("Authorization response is nil.")
#endif
                    completion(false, SSOError.unknownError(error))
                    return
                }
                
#if DEBUG
                print("Authorization response: \(response)")
#endif
                self.stateHandler.setAuthState(nil)
                
                completion(true, nil)
            }
    }
    
}

enum AppAuthConstants {
    static let ssoLoginHint = "login_hint"
}

public extension SSOAuthentication {
    
    public enum SSOError: Error {
        case autherizationCancelled
        case errorWithDescription(String)
        case unknownError(_ error: Error?)
        
        init(errorCode: OIDErrorCode, _ error: Error?) {
            switch errorCode {
            case OIDErrorCode.userCanceledAuthorizationFlow:
                self = .autherizationCancelled
            default:
                self = .unknownError(error)
            }
        }
    }
}
