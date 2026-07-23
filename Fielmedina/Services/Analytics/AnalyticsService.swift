//
//  FirebaseUtils.swift
//  Fielmedina
//
//  Created by Aslan on 1/8/26.
//

import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebaseMessaging
import FirebaseRemoteConfig
import UserNotifications
import UIKit

class FirebaseUtils {
    static let TAG = "FirebaseUtils"
    private static let FCM_TOKEN_KEY = "fcm_token"
    private static let FCM_TOKEN_TIMESTAMP_KEY = "fcm_token_timestamp"
    private static let remoteConfig = RemoteConfig.remoteConfig()
    private static var isFCMInitialized = false
    private static var pendingDefaultTopicSubscription = false
    
    // MARK: - FCM (Firebase Cloud Messaging)
    
    static func initializeFCM() {
        guard !isFCMInitialized else {
            LogUtils.d(TAG, "FCM already initialized, skipping...")
            return
        }
        
        LogUtils.d(TAG, "Initializing FCM...")
        
        Messaging.messaging().delegate = FCMDelegate.shared
        
        // Removed subscribeToDefaultTopics from here to avoid race condition with APNS
        isFCMInitialized = true
    }
    
    static func getFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                LogUtils.e(TAG, "Error fetching FCM registration token: \(error.localizedDescription)")
                return
            }
            
            if let token = token {
                LogUtils.d(TAG, "FCM Token retrieved successfully")
                saveTokenLocally(token)

                // Sync with backend
                Task {
                    await SyncService.shared.registerDevice(token: token)
                }
            }
        }
    }
    
    static func saveTokenLocally(_ token: String) {
        KeychainStore.set(token, forKey: FCM_TOKEN_KEY)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: FCM_TOKEN_TIMESTAMP_KEY)
        UserDefaults.standard.removeObject(forKey: FCM_TOKEN_KEY)
        LogUtils.d(TAG, "Token saved securely in Keychain")
    }
    
    static func getSavedToken() -> String? {
        if let token = KeychainStore.string(forKey: FCM_TOKEN_KEY) {
            return token
        }
        
        // Migration check
        if let oldToken = UserDefaults.standard.string(forKey: FCM_TOKEN_KEY) {
            saveTokenLocally(oldToken)
            return oldToken
        }
        
        return nil
    }
    
    static func subscribeToDefaultTopics() {
        guard Messaging.messaging().apnsToken != nil else {
            pendingDefaultTopicSubscription = true
            LogUtils.w(TAG, "APNS token not available yet. Deferring topic subscription.")
            return
        }

        LogUtils.d(TAG, "Subscribing to default topics...")
        
        let topics = ["filmedina_updates", "new_places", "new_routes", "app_updates"]
        
        for topic in topics {
            Messaging.messaging().subscribe(toTopic: topic) { error in
                if let error = error {
                    LogUtils.e(TAG, "Failed to subscribe to topic \(topic): \(error.localizedDescription)")
                } else {
                    LogUtils.d(TAG, "Subscribed to topic: \(topic)")
                }
            }
        }
    }

    static func handleAPNSTokenDidSet() {
        guard pendingDefaultTopicSubscription else { return }
        pendingDefaultTopicSubscription = false
        subscribeToDefaultTopics()
    }
    
    static func subscribeToTopic(_ topic: String) {
        Messaging.messaging().subscribe(toTopic: topic) { error in
            if let error = error {
                LogUtils.e(TAG, "Failed to subscribe to topic \(topic): \(error.localizedDescription)")
            } else {
                LogUtils.d(TAG, "Subscribed to topic: \(topic)")
            }
        }
    }
    
    static func unsubscribeFromTopic(_ topic: String) {
        Messaging.messaging().unsubscribe(fromTopic: topic) { error in
            if let error = error {
                LogUtils.e(TAG, "Failed to unsubscribe from topic \(topic): \(error.localizedDescription)")
            } else {
                LogUtils.d(TAG, "Unsubscribed from topic: \(topic)")
            }
        }
    }
    
    // MARK: - Remote Config
    
    static func initializeRemoteConfig() {
        LogUtils.d(TAG, "Initializing Remote Config...")
        
        let defaults: [String: NSObject] = [
            "enable_hiking_features": true as NSObject,
            "enable_advanced_navigation": false as NSObject,
            "map_zoom_level": 14 as NSObject,
            "emergency_contacts_enabled": true as NSObject,
            "story_gallery_enabled": true as NSObject,
            "fcm_debug_mode": false as NSObject,
            "analytics_enabled": true as NSObject,
            "crashlytics_enabled": true as NSObject
        ]
        
        remoteConfig.setDefaults(defaults)
        
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600
        #if DEBUG
        settings.minimumFetchInterval = 0
        #endif
        remoteConfig.configSettings = settings
        
        fetchAndActivateRemoteConfig()
    }
    
    static func fetchAndActivateRemoteConfig() {
        remoteConfig.fetchAndActivate { status, error in
            if let error = error {
                LogUtils.e(TAG, "Remote Config fetch failed: \(error.localizedDescription)")
                FirebaseUtils.logError(error, additionalUserInfo: ["context": "remote_config_fetch"])
                return
            }
            
            LogUtils.d(TAG, "Remote Config activated successfully")
            FirebaseUtils.logFCMEvent(event: "remote_config_activated", details: "status: \(status.rawValue)")
            
            logRemoteConfigValues()
        }
    }
    
    static func getRemoteConfigBool(forKey key: String) -> Bool {
        return remoteConfig.configValue(forKey: key).boolValue
    }
    
    static func getRemoteConfigString(forKey key: String) -> String {
        return remoteConfig.configValue(forKey: key).stringValue
    }
    
    static func getRemoteConfigNumber(forKey key: String) -> NSNumber {
        return remoteConfig.configValue(forKey: key).numberValue
    }
    
    private static func logRemoteConfigValues() {
        let values: [String: Any] = [
            "enable_hiking_features": getRemoteConfigBool(forKey: "enable_hiking_features"),
            "enable_advanced_navigation": getRemoteConfigBool(forKey: "enable_advanced_navigation"),
            "map_zoom_level": getRemoteConfigNumber(forKey: "map_zoom_level"),
            "emergency_contacts_enabled": getRemoteConfigBool(forKey: "emergency_contacts_enabled"),
            "story_gallery_enabled": getRemoteConfigBool(forKey: "story_gallery_enabled"),
            "fcm_debug_mode": getRemoteConfigBool(forKey: "fcm_debug_mode"),
            "analytics_enabled": getRemoteConfigBool(forKey: "analytics_enabled"),
            "crashlytics_enabled": getRemoteConfigBool(forKey: "crashlytics_enabled")
        ]
        
        for (key, value) in values {
            FirebaseUtils.logCustomKey(key: "remote_config_\(key)", value: value)
        }
    }
    
    // MARK: - Analytics
    
    static func trackScreenView(screenName: String, screenClass: String? = nil) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass ?? screenName
        ])
        LogUtils.d(TAG, "Screen view tracked: \(screenName)")
    }
    
    static func trackButtonTap(buttonName: String, screenName: String) {
        Analytics.logEvent("button_tap", parameters: [
            "button_name": buttonName,
            "screen_name": screenName,
            "timestamp": Date().timeIntervalSince1970
        ])
        LogUtils.d(TAG, "Button tap tracked: \(buttonName) on \(screenName)")
    }
    
    static func trackFeatureUsage(featureName: String, parameters: [String: Any]? = nil) {
        DispatchQueue.global(qos: .utility).async {
            var eventParams: [String: Any] = [
                "feature_name": featureName,
                "timestamp": Date().timeIntervalSince1970
            ]
            if let params = parameters {
                eventParams.merge(params) { _, new in new }
            }
            Analytics.logEvent("feature_used", parameters: eventParams)
            LogUtils.d(TAG, "Feature usage tracked: \(featureName)")
        }
    }
    
    static func trackNavigation(from: String, to: String) {
        DispatchQueue.global(qos: .utility).async {
            Analytics.logEvent("navigation", parameters: [
                "from_screen": from,
                "to_screen": to,
                "timestamp": Date().timeIntervalSince1970
            ])
            LogUtils.d(TAG, "Navigation tracked: \(from) -> \(to)")
        }
    }
    
    static func trackMapEvent(event: String, details: String = "") {
        DispatchQueue.global(qos: .utility).async {
            Analytics.logEvent("map_event", parameters: [
                "event_type": event,
                "details": details,
                "timestamp": Date().timeIntervalSince1970
            ])
            LogUtils.d(TAG, "Map event tracked: \(event) - \(details)")
        }
    }
    
    static func trackLocationEvent(event: String, accuracy: Double? = nil) {
        var params: [String: Any] = [
            "event_type": event,
            "timestamp": Date().timeIntervalSince1970
        ]
        if let accuracy = accuracy {
            params["accuracy"] = accuracy
        }
        Analytics.logEvent("location_event", parameters: params)
        LogUtils.d(TAG, "Location event tracked: \(event)")
    }
    
    // MARK: - Crashlytics
    
    static func logUserInfo(userId: String, email: String? = nil, name: String? = nil) {
        Crashlytics.crashlytics().setUserID(userId)
        if let email = email {
            Crashlytics.crashlytics().setCustomValue(email, forKey: "user_email")
        }
        if let name = name {
            Crashlytics.crashlytics().setCustomValue(name, forKey: "user_name")
        }
        LogUtils.d(TAG, "User info logged for: \(userId)")
    }
    
    static func logCustomKey(key: String, value: Any) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    static func logError(_ error: Error, additionalUserInfo: [String: Any]? = nil) {
        if let additionalInfo = additionalUserInfo {
            Crashlytics.crashlytics().record(error: error, userInfo: additionalInfo)
        } else {
            Crashlytics.crashlytics().record(error: error)
        }
        LogUtils.e(TAG, "Error logged to Crashlytics: \(error.localizedDescription)")
    }
    
    static func logNonFatalError(_ error: Error, additionalUserInfo: [String: Any]? = nil) {
        logError(error, additionalUserInfo: additionalUserInfo)
    }
    
    static func logNavigation(from: String, to: String) {
        Crashlytics.crashlytics().log("Navigation: \(from) -> \(to)")
        Crashlytics.crashlytics().setCustomValue(from, forKey: "last_navigation_from")
        Crashlytics.crashlytics().setCustomValue(to, forKey: "last_navigation_to")
        Crashlytics.crashlytics().setCustomValue(Date().timeIntervalSince1970, forKey: "navigation_timestamp")
    }
    
    static func logMapEvent(event: String, details: String = "") {
        Crashlytics.crashlytics().log("Map Event: \(event) - \(details)")
        Crashlytics.crashlytics().setCustomValue(event, forKey: "last_map_event")
        Crashlytics.crashlytics().setCustomValue(details, forKey: "last_map_details")
        Crashlytics.crashlytics().setCustomValue(Date().timeIntervalSince1970, forKey: "map_event_timestamp")
    }
    
    static func logFCMEvent(event: String, details: String = "") {
        Crashlytics.crashlytics().log("FCM Event: \(event) - \(details)")
        Crashlytics.crashlytics().setCustomValue(event, forKey: "last_fcm_event")
        Crashlytics.crashlytics().setCustomValue(details, forKey: "last_fcm_details")
        Crashlytics.crashlytics().setCustomValue(Date().timeIntervalSince1970, forKey: "fcm_event_timestamp")
    }
    
    static func logLocationEvent(event: String, accuracy: Double? = nil) {
        var message = "Location Event: \(event)"
        if let accuracy = accuracy {
            message += " - Accuracy: \(accuracy)m"
        }
        Crashlytics.crashlytics().log(message)
        
        Crashlytics.crashlytics().setCustomValue(event, forKey: "last_location_event")
        Crashlytics.crashlytics().setCustomValue(Date().timeIntervalSince1970, forKey: "location_event_timestamp")
        
        if let accuracy = accuracy {
            Crashlytics.crashlytics().setCustomValue(accuracy, forKey: "last_location_accuracy")
        }
    }
    
    static func logUserAction(action: String, screen: String = "") {
        let message = "User Action: \(action) \(screen.isEmpty ? "" : "on \(screen)")"
        Crashlytics.crashlytics().log(message)
        Crashlytics.crashlytics().setCustomValue(action, forKey: "last_user_action")
        Crashlytics.crashlytics().setCustomValue(screen, forKey: "last_screen")
        Crashlytics.crashlytics().setCustomValue(Date().timeIntervalSince1970, forKey: "user_action_timestamp")
    }
    
    static func setAppState(
        isOnline: Bool,
        hasLocationPermission: Bool,
        isNavigating: Bool,
        currentScreen: String
    ) {
        Crashlytics.crashlytics().setCustomValue(isOnline, forKey: "is_online")
        Crashlytics.crashlytics().setCustomValue(hasLocationPermission, forKey: "has_location_permission")
        Crashlytics.crashlytics().setCustomValue(isNavigating, forKey: "is_navigating")
        Crashlytics.crashlytics().setCustomValue(currentScreen, forKey: "current_screen")
        Crashlytics.crashlytics().setCustomValue(Date().timeIntervalSince1970, forKey: "app_state_timestamp")
    }
    
    // MARK: - Main Initialization
    
    static func initializeFirebase() {
        LogUtils.d(TAG, "Initializing Firebase services...")
        
        // Enable Crashlytics collection
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        
        // Enable Analytics collection
        Analytics.setAnalyticsCollectionEnabled(true)
        
        // Initialize Remote Config
        initializeRemoteConfig()
        
        // Set app metadata for Crashlytics
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            Crashlytics.crashlytics().setCustomValue(version, forKey: "app_version")
            Crashlytics.crashlytics().setCustomValue(build, forKey: "build_number")
            Crashlytics.crashlytics().setCustomValue(Bundle.main.bundleIdentifier ?? "unknown", forKey: "bundle_id")
            Crashlytics.crashlytics().setCustomValue(UIDevice.current.model, forKey: "device_model")
            Crashlytics.crashlytics().setCustomValue(UIDevice.current.systemVersion, forKey: "ios_version")
            Crashlytics.crashlytics().setCustomValue(Date().timeIntervalSince1970, forKey: "init_timestamp")
        }
        
        LogUtils.d(TAG, "Firebase initialization completed")
    }
    
    // MARK: - Testing Functions
    
    static func testCrashlytics() {
        // This will cause a crash for testing Crashlytics
        // Uncomment only for testing purposes
        // fatalError("Test crash for Crashlytics")
        LogUtils.w(TAG, "testCrashlytics() called but disabled for safety")
    }
    
    static func testAnalytics() {
        Analytics.logEvent("test_event", parameters: [
            "test_parameter": "test_value",
            "timestamp": Date().timeIntervalSince1970
        ])
        LogUtils.d(TAG, "Test analytics event sent")
    }
    
    static func testFCM() {
        LogUtils.d(TAG, "Testing FCM functionality...")
        getFCMToken()
        subscribeToTopic("test_topic")
    }
    
    static func testRemoteConfig() {
        LogUtils.d(TAG, "Testing Remote Config functionality...")
        fetchAndActivateRemoteConfig()
    }
}


// MARK: - FCM Delegate

class FCMDelegate: NSObject, MessagingDelegate {
    static let shared = FCMDelegate()
    
    private override init() {
        super.init()
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        LogUtils.d(FirebaseUtils.TAG, "FCM registration token refreshed")
        
        if let token = fcmToken {
            FirebaseUtils.saveTokenLocally(token)
            
            // Now that we have a token, it's safe to subscribe to topics
            FirebaseUtils.subscribeToDefaultTopics()
            
            // Sync with backend
            Task {
                await SyncService.shared.registerDevice(token: token)
            }
        }
    }
}


// MARK: - Logging Utilities

class LogUtils {
    static func d(_ tag: String, _ message: String) {
        #if DEBUG
        print("📱 [\(tag)] \(message)")
        #endif
    }
    
    static func e(_ tag: String, _ message: String, _ error: Error? = nil) {
        #if DEBUG
        if let error = error {
            print("❌ [\(tag)] \(message) - Error: \(error.localizedDescription)")
        } else {
            print("❌ [\(tag)] \(message)")
        }
        #endif
    }
    
    static func w(_ tag: String, _ message: String, _ error: Error? = nil) {
        #if DEBUG
        if let error = error {
            print("⚠️ [\(tag)] \(message) - Error: \(error.localizedDescription)")
        } else {
            print("⚠️ [\(tag)] \(message)")
        }
        #endif
    }
    
    static func i(_ tag: String, _ message: String) {
        #if DEBUG
        print("ℹ️ [\(tag)] \(message)")
        #endif
    }
}
