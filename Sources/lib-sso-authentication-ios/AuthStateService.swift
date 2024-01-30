//
//  File.swift
//  lib-sso-authentication-ios
//
//  Created by Ankush Kushwaha on 22/01/25.
//

import Foundation
import AppAuth

public struct AuthStateService {
    
    private(set) var savedAuthState: OIDAuthState?
    private let kAppAuthStateKey: String = "kAppAuthStateKey"
    private let userDefaultSuiteName: String = "com.omm.appauth"

    init() {
        loadState()
    }

    private func saveState() {

        var data: Data?

        if let savedAuthState = self.savedAuthState {
            data = NSKeyedArchiver.archivedData(withRootObject: savedAuthState)
        }

        if let userDefaults = UserDefaults(suiteName: userDefaultSuiteName) {
            userDefaults.set(data, forKey: kAppAuthStateKey)
            userDefaults.synchronize()
        }
    }

    mutating func loadState() {
        guard let data = UserDefaults(suiteName: userDefaultSuiteName)?.object(forKey: kAppAuthStateKey) as? Data else {
            return
        }

        if let authState = NSKeyedUnarchiver.unarchiveObject(with: data) as? OIDAuthState {
            self.setAuthState(authState)
        }
    }

    mutating func setAuthState(_ authState: OIDAuthState?) {
        self.savedAuthState = authState
        self.saveState()
    }
}
