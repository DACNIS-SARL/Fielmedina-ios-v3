//
//  DataSyncManager.swift
//  Fielmedina
//
//  Created by Aslan on 1/7/26.
//

import SwiftUI
import FirebaseMessaging

@Observable
class DataSyncManager {
    static let shared = DataSyncManager()
    
    private var fcmToken: String?
    private var deviceUUID: String {
        // Get or create persistent device UUID
        if let uuid = UserDefaults.standard.string(forKey: "deviceUUID") {
            return uuid
        } else {
            let newUUID = UUID().uuidString
            UserDefaults.standard.set(newUUID, forKey: "deviceUUID")
            LogUtils.d("DataSyncManager", "Generated new device UUID: \(newUUID)")
            return newUUID
        }
    }
    
    private init() {}
    
    // MARK: - FCM Token Registration
    
    /// Call this method when the app launches or when FCM token is refreshed
    func registerFCMDevice() {
        LogUtils.d("DataSyncManager", "Starting FCM device registration...")
        
        // Get FCM token
        Messaging.messaging().token { token, error in
            if let error = error {
                LogUtils.e("DataSyncManager", "Error fetching FCM registration token", error)
                FirebaseUtils.logError(error, additionalUserInfo: ["context": "fcm_device_registration"])
                return
            }
            
            guard let token = token else {
                LogUtils.w("DataSyncManager", "FCM token is nil")
                return
            }
            
            LogUtils.d("DataSyncManager", "FCM Token retrieved successfully")
            self.fcmToken = token
            self.sendFCMTokenToBackend(token: token)
        }
    }
    
    /// Send FCM token to Django backend via GraphQL
    private func sendFCMTokenToBackend(token: String) {
        let deviceName = UIDevice.current.name
        let deviceType = "ios"
        let userUid = deviceUUID // Use device UUID instead of user auth
        
        LogUtils.d("DataSyncManager", "Sending FCM token to backend for device: \(deviceName)")
        
        // Direct GraphQL API call
        guard let url = URL(string: "https://mystory.fielmedina.com/graphql") else {
            LogUtils.e("DataSyncManager", "Invalid GraphQL endpoint URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header if your API requires it
        // request.setValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")
        
        let query = """
        mutation {
          registerFcmDevice(
            registrationId: "\(token)"
            type: "\(deviceType)"
            userUid: "\(userUid)"
            name: "\(deviceName)"
          ) {
            ok
            message
          }
        }
        """
        
        let body: [String: Any] = ["query": query]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                LogUtils.e("DataSyncManager", "Network error sending FCM token", error)
                FirebaseUtils.logError(error, additionalUserInfo: [
                    "context": "fcm_backend_registration",
                    "device_uuid": userUid
                ])
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                LogUtils.d("DataSyncManager", "Backend response status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    LogUtils.w("DataSyncManager", "Non-200 status code from backend: \(httpResponse.statusCode)")
                }
            }
            
            if let data = data {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    LogUtils.d("DataSyncManager", "Backend response: \(json)")
                    
                    // Check if registration was successful
                    if let data = json["data"] as? [String: Any],
                       let registerFcmDevice = data["registerFcmDevice"] as? [String: Any],
                       let ok = registerFcmDevice["ok"] as? Bool {
                        
                        if ok {
                            LogUtils.d("DataSyncManager", "✅ FCM device registered successfully")
                            
                            // Track successful registration using your existing FirebaseUtils
                            FirebaseUtils.trackFeatureUsage(
                                featureName: "fcm_device_registered",
                                parameters: [
                                    "device_type": deviceType,
                                    "device_uuid": userUid,
                                    "device_name": deviceName
                                ]
                            )
                            
                            // Log to Crashlytics
                            FirebaseUtils.logFCMEvent(
                                event: "device_registered",
                                details: "Device UUID: \(userUid), Name: \(deviceName)"
                            )
                        } else {
                            let message = registerFcmDevice["message"] as? String ?? "Unknown error"
                            LogUtils.e("DataSyncManager", "FCM registration failed: \(message)")
                            
                            FirebaseUtils.logFCMEvent(
                                event: "device_registration_failed",
                                details: message
                            )
                        }
                    }
                    
                    // Check for GraphQL errors
                    if let errors = json["errors"] as? [[String: Any]] {
                        LogUtils.e("DataSyncManager", "GraphQL errors: \(errors)")
                        
                        FirebaseUtils.logFCMEvent(
                            event: "device_registration_error",
                            details: "GraphQL errors: \(errors)"
                        )
                    }
                }
            }
        }.resume()
    }
    
    /// Get the device UUID for reference
    func getDeviceUUID() -> String {
        return deviceUUID
    }
    
    /// Get current FCM token if available
    func getCurrentFCMToken() -> String? {
        return fcmToken
    }
    
    /// Clear device registration (for testing or reset)
    func clearDeviceRegistration() {
        self.fcmToken = nil
        UserDefaults.standard.removeObject(forKey: "deviceUUID")
        LogUtils.d("DataSyncManager", "Device registration cleared")
        
        FirebaseUtils.logFCMEvent(
            event: "device_registration_cleared",
            details: "User manually cleared device registration"
        )
    }
    
    /// Force refresh and re-register FCM token
    func forceRefreshFCMToken() {
        LogUtils.d("DataSyncManager", "Forcing FCM token refresh...")
        
        Messaging.messaging().deleteToken { error in
            if let error = error {
                LogUtils.e("DataSyncManager", "Error deleting FCM token", error)
                return
            }
            
            LogUtils.d("DataSyncManager", "FCM token deleted, requesting new token...")
            self.registerFCMDevice()
        }
    }
}

// MARK: - Extension for FCMDelegate Integration

extension FCMDelegate {
    
    /// Override or add this to handle token refresh
    func handleTokenRefresh(_ token: String) {
        LogUtils.d("DataSyncManager", "FCM token refreshed via delegate")
        
        // Automatically register device when token refreshes
        DataSyncManager.shared.registerFCMDevice()
    }
}
