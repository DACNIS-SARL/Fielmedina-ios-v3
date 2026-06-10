//
//  FielmedinaApp.swift
//  Fielmedina
//
//  Created by Aslan on 1/7/26.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import MapboxCommon
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

        LogConfiguration.setLoggingLevelForUpTo(NSNumber(value: LoggingLevel.error.rawValue))

        CacheConfigurator.configureURLCache()
        
        _ = MapboxNavigationProviderStore.shared
        
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        LogUtils.d("AppDelegate", "✅ APNS token received successfully")
        
        Messaging.messaging().apnsToken = deviceToken
        FirebaseUtils.handleAPNSTokenDidSet()
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
        UNUserNotificationCenter.current().setBadgeCount(0)
        let userInfo = response.notification.request.content.userInfo
        LogUtils.d("AppDelegate", "👆 Notification tapped: \(userInfo)")
        
       
        FirebaseUtils.trackFeatureUsage(featureName: "notification_tapped",
                                       parameters: ["notification_id": userInfo["notification_id"] ?? "unknown"])
        
        
        FirebaseUtils.logFCMEvent(event: "notification_tapped",
                                  details: "data: \(userInfo)")
        
        // Handle deep linking or navigation based on notification data
        // Expecting a payload like { "screen": "map" } or { "target_screen": "hiking" }
        // Dispatch async to ensure MainNavigationView has subscribed on cold launch
        DispatchQueue.main.async {
            if let screen = (userInfo["screen"] as? String) ?? (userInfo["target_screen"] as? String) {
                LogUtils.d("AppDelegate", "🔗 Deep link target screen: \(screen)")
                NotificationCenter.default.post(name: .pushDeepLink,
                                                object: nil,
                                                userInfo: [
                                                    "screen": screen,
                                                    "payload": userInfo
                                                ])
            } else {
                NotificationCenter.default.post(name: .pushDeepLink,
                                                object: nil,
                                                userInfo: [
                                                    "payload": userInfo
                                                ])
            }
        }
        
        completionHandler()
    }
}

extension Notification.Name {
    static let pushDeepLink = Notification.Name("push_deep_link")
}


@main
struct FielmedinaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var locationManager = LocationManager()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            MainNavigationView().environment(locationManager)
                .onAppear {
                    locationManager.requestPermission()
                    checkAndHandleAppUpdate()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                UNUserNotificationCenter.current().setBadgeCount(0)
            }
        }
    }

    private func checkAndHandleAppUpdate() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        let currentVersionFull = "\(currentVersion).\(currentBuild)"

        let storedVersion = UserDefaults.standard.string(forKey: "last_known_app_version") ?? ""

        if storedVersion != currentVersionFull {
            // App was updated or first launch — reset prefetch so new content gets downloaded
            OfflineContentPrefetcher.shared.markNeedsRefresh()
            UserDefaults.standard.set(currentVersionFull, forKey: "last_known_app_version")
        }
    }
}
