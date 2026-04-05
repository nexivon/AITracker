//
//  AITrackerApp.swift
//  AITracker
//
//  Created by Murat Tufan on 19.03.2026.
//

import SwiftUI

@main
struct AITrackerApp: App {
    init() {
        migrateAPIKeyToKeychain()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func migrateAPIKeyToKeychain() {
        let userDefaultsKey = "geminiAPIKey"
        if let storedKey = UserDefaults.standard.string(forKey: userDefaultsKey) {
            // Sadece UserDefaults'ta varsa ve Keychain bomboşsa aktar
            if KeychainManager.shared.loadString(key: userDefaultsKey) == nil {
                KeychainManager.shared.saveString(key: userDefaultsKey, value: storedKey)
            }
            // Artık güvensiz alanda tutmaya gerek yok sil
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        }
    }
}
