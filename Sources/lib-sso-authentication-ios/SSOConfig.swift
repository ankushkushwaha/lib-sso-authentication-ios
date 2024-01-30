//
//  SSOConfig.swift
//  lib-sso-authentication-ios
//
//  Created by Ankush Kushwaha on 22/01/25.
//


public struct SSOConfig {
    let issuer: String
    let clientID: String
    let redirectUri: String
    let postLogoutRedirectUri: String
    let scope: [String]
    let autherizationUrl: String
    let tokenEndpoint: String
    let logoutUrl: String
}
