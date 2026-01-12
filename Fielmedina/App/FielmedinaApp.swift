//
//  FielmedinaApp.swift
//  Fielmedina
//
//  Created by Aslan on 1/7/26.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                LogUtils.d("AppDelegate", "Notification permission granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                LogUtils.w("AppDelegate", "Notification permission denied")
            }
            
            if let error = error {
                LogUtils.e("AppDelegate", "Error requesting notification permission: \(error.localizedDescription)")
            }
        }
        
        UNUserNotificationCenter.current().delegate = self
        
        FirebaseUtils.initializeFirebase()
        FirebaseUtils.initializeFCM()
        
        return true
    }
    
    // MARK: - APNS Token Handling
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        LogUtils.d("AppDelegate", "✅ APNS token received successfully")
        
        Messaging.messaging().apnsToken = deviceToken
        
        FirebaseUtils.getFCMToken()
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        LogUtils.e("AppDelegate", "❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
}


extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        LogUtils.d("AppDelegate", "📬 Notification received in foreground")
        
        FirebaseUtils.logFCMEvent(event: "notification_received_foreground",
                                  details: "title: \(notification.request.content.title)")
        
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        LogUtils.d("AppDelegate", "👆 Notification tapped: \(userInfo)")
        
       
        FirebaseUtils.trackFeatureUsage(featureName: "notification_tapped",
                                       parameters: ["notification_id": userInfo["notification_id"] ?? "unknown"])
        
        
        FirebaseUtils.logFCMEvent(event: "notification_tapped",
                                  details: "data: \(userInfo)")
        
        // Handle deep linking or navigation based on notification data
        // Expecting a payload like { "screen": "map" } or { "target_screen": "hiking" }
        if let screen = (userInfo["screen"] as? String) ?? (userInfo["target_screen"] as? String) {
            LogUtils.d("AppDelegate", "🔗 Deep link target screen: \(screen)")
            NotificationCenter.default.post(name: .pushDeepLink,
                                            object: nil,
                                            userInfo: [
                                                "screen": screen,
                                                "payload": userInfo
                                            ])
        } else {
            // Post generic payload so listeners can decide how to handle it
            NotificationCenter.default.post(name: .pushDeepLink,
                                            object: nil,
                                            userInfo: [
                                                "payload": userInfo
                                            ])
        }
        
        completionHandler()
    }
}

extension Notification.Name {
    /// Posted when a push notification is tapped and the app should navigate based on payload.
    static let pushDeepLink = Notification.Name("push_deep_link")
}

// MARK: - Main App

@main
struct FielmedinaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var locationManager = LocationManager()
    
    
    var body: some Scene {
        WindowGroup {
            MainNavigationView().environment(locationManager)
                .onAppear {
                    locationManager.requestPermission()
                    DataSyncManager.shared.registerFCMDevice()
                }
        }
    }
}
