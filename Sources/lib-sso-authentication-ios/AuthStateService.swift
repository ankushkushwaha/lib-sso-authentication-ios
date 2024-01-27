//
//  File.swift
//  lib-sso-authentication-ios
//
//  Created by Ankush Kushwaha on 22/01/25.
//

import Foundation
import AppAuth

public struct AuthStateService {
    
    private let key = "com.roadnet.authApp.authState"
    
    func saveAuthState(_ authState: OIDAuthState) {
        do {
            let archivedData = try NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: true)
            UserDefaults.standard.set(archivedData, forKey: key)
            UserDefaults.standard.synchronize()
            print("AuthState saved successfully.")
        } catch {
            print("Error saving AuthState: \(error.localizedDescription)")
        }
    }
    
    func getAuthState() -> OIDAuthState? {
        guard let archivedData = UserDefaults.standard.data(forKey: key) else {
            print("No AuthState found in storage.")
            return nil
        }
        do {
            let authState = try NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: archivedData)
            print("AuthState loaded successfully.")
            return authState
        } catch {
            print("Error loading AuthState: \(error.localizedDescription)")
            return nil
        }
    }

}
