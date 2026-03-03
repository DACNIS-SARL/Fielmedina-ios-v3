//
//  SyncService.swift
//  Fielmedina
//
//  Created by Aslan on 1/7/26.
//

import Foundation
import Apollo
import UIKit

actor SyncService {
    static let shared = SyncService()
    
    private let DEVICE_UUID_KEY = "deviceUUID"
    private let LAST_REGISTERED_TOKEN_KEY = "lastRegisteredFCMToken"
    
    private init() {}
    
    private var cachedUUID: UUID?
    
    var deviceUUID: UUID {
        get {
            if let cached = cachedUUID {
                return cached
            }
            
            // Try loading from Keychain
            if let uuidString = KeychainStore.string(forKey: DEVICE_UUID_KEY),
               let uuid = UUID(uuidString: uuidString) {
                cachedUUID = uuid
                return uuid
            }
            
            // Migration check: If not in Keychain but in UserDefaults, move it
            if let oldUUIDString = UserDefaults.standard.string(forKey: DEVICE_UUID_KEY),
               let uuid = UUID(uuidString: oldUUIDString) {
                KeychainStore.set(oldUUIDString, forKey: DEVICE_UUID_KEY)
                UserDefaults.standard.removeObject(forKey: DEVICE_UUID_KEY)
                cachedUUID = uuid
                return uuid
            }
            
            // Fresh generation
            let newUUID = UUID()
            KeychainStore.set(newUUID.uuidString, forKey: DEVICE_UUID_KEY)
            cachedUUID = newUUID
            LogUtils.d("SyncService", "Generated fresh secure device UUID: \(newUUID.uuidString)")
            return newUUID
        }
    }
    
    private var debounceTask: Task<Void, Never>?

    func registerDevice(token: String, force: Bool = false) async {
        debounceTask?.cancel()
        
        let lastToken = KeychainStore.string(forKey: LAST_REGISTERED_TOKEN_KEY) ?? 
                        UserDefaults.standard.string(forKey: LAST_REGISTERED_TOKEN_KEY)
        
        if !force && lastToken == token {
            LogUtils.d("SyncService", "Token \(token.prefix(5))... already registered. Skipping.")
            return
        }
        
        debounceTask = Task {
            do {
                try await Task.sleep(for: .seconds(3))
            } catch {
                return
            }
            
            if Task.isCancelled { return }
            
            let uuid = self.deviceUUID.uuidString
            let deviceName = await UIDevice.current.name
            let deviceType = "ios"
            
            // Detect device language matched against app supported localizations (e.g. "en", "fr")
            let deviceLanguage = Bundle.main.preferredLocalizations.first ?? "en"
            
            LogUtils.d("SyncService", "🚀 Registering LATEST token [ID: \(uuid.suffix(5))]: \(token.prefix(10))... (lang=\(deviceLanguage))")
            
            let mutation = FielmedinaAPI.RegisterFcmDeviceMutation(
                registrationId: token,
                type: deviceType,
                userUid: uuid,
                name: .some(deviceName),
                language: .some(deviceLanguage)
            )
            
            do {
                let result = try await Network.shared.apollo.perform(mutation: mutation)
                
                if let registerResult = result.data?.registerFcmDevice {
                    if registerResult.ok {
                        LogUtils.d("SyncService", "✅ FCM device registered successfully: \(registerResult.message ?? "Success")")
                        self.markTokenAsRegistered(token)
                    } else {
                        LogUtils.e("SyncService", "❌ FCM registration failed: \(registerResult.message ?? "Unknown error")")
                    }
                }
            } catch {
                if !Task.isCancelled {
                    LogUtils.e("SyncService", "❌ Error performing FCM registration mutation", error)
                }
            }
        }
    }
    
    private func markTokenAsRegistered(_ token: String) {
        KeychainStore.set(token, forKey: LAST_REGISTERED_TOKEN_KEY)
        UserDefaults.standard.removeObject(forKey: LAST_REGISTERED_TOKEN_KEY)
    }
}
