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
    
    private var currentAuthorizationFlow: OIDExternalUserAgentSession?
    private var authState: OIDAuthState?

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

        // Start authorization flow
        currentAuthorizationFlow = OIDAuthState.authState(
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
            completion(accessToken, nil)
        }
    }
}
