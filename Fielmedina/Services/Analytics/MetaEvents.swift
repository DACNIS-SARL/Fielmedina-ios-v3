//
//  MetaEvents.swift
//  Fielmedina
//


import Foundation
import AppTrackingTransparency
import FacebookCore

@MainActor
enum MetaEvents {

    private static let TAG = "MetaEvents"

    /// The ATT prompt is shown once, after onboarding, never at cold start —
    /// stacking it on top of the notification and location prompts is the fastest
    /// way to get denied.
    private static var hasRequestedTracking = false

    // MARK: - Custom event names

    /// Product-specific conversions. Standard Meta events are used wherever one
    /// genuinely fits; these cover the actions unique to a medina guide.
    /// Keep in sync with Android's `MetaEvents.Event`.
    enum Custom {
        static let startHiking = AppEvents.Name("StartHiking")
        static let startNavigation = AppEvents.Name("StartNavigation")
        static let playAudioGuide = AppEvents.Name("PlayAudioGuide")
    }

    // MARK: - Setup

    /// Boots the Meta SDK. Must run in `didFinishLaunchingWithOptions`, before any
    /// event is logged.
    static func initializeSDK(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) {
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        #if DEBUG
        // Prints every event as it is queued and flushed. Pair this with Events
        // Manager → Test Events to confirm an event both leaves the device and
        // arrives at Meta — the SDK failing silently is exactly how this went
        // unnoticed for so long.
        Settings.shared.enableLoggingBehavior(.appEvents)
        LogUtils.d(TAG, "Meta SDK initialised — ATT status: \(ATTrackingManager.trackingAuthorizationStatus.rawValue)")
        #endif
    }

    /// Logs the app-activation event. Call from `applicationDidBecomeActive`.
    static func activateApp() {
        AppEvents.shared.activateApp()
    }

    @discardableResult
    static func handleUserActivity(
        _ application: UIApplication,
        userActivity: NSUserActivity
    ) -> Bool {
        ApplicationDelegate.shared.application(application, continue: userActivity)
    }

    @discardableResult
    static func handleOpenURL(
        _ application: UIApplication,
        url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any]
    ) -> Bool {
        ApplicationDelegate.shared.application(application, open: url, options: options)
    }


    static func requestTrackingAuthorizationIfNeeded() async {
        guard !hasRequestedTracking else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            hasRequestedTracking = true   // already answered in an earlier session
            return
        }

        let status = await ATTrackingManager.requestTrackingAuthorization()

        if status != .notDetermined {
            hasRequestedTracking = true
        }
        LogUtils.d(TAG, "ATT prompt answered: \(status.rawValue)")
    }

    // MARK: - Standard conversions

    /// A place, event or merchant detail screen was opened. Meta's `ViewContent`.
    static func logContentView(contentType: String, contentId: String, contentName: String) {
        AppEvents.shared.logEvent(.viewedContent, parameters: [
            .contentType: contentType,
            .contentID: contentId,
            .description: contentName
        ])
    }

    /// Keep in sync with Android `MetaEvents.logSearch(resultCount:)`.
    static func logSearch(resultCount: Int) {
        AppEvents.shared.logEvent(.searched, parameters: [
            .contentType: "global_search",
            .success: resultCount > 0 ? 1 : 0
        ])
    }

    /// Onboarding finished. Meta's `CompletedTutorial`.
    static func logOnboardingCompleted() {
        AppEvents.shared.logEvent(.completedTutorial, parameters: [.success: 1])
    }

  
    static func logOfflineRegionDownloaded(regionId: String) {
        AppEvents.shared.logEvent(.unlockedAchievement, parameters: [
            .description: "offline_region_downloaded",
            .contentID: regionId
        ])
    }

    // MARK: - Custom conversions

    /// The user started a hiking route — the deepest intent signal the app has.
    static func logHikingStarted(routeId: String, routeName: String) {
        AppEvents.shared.logEvent(Custom.startHiking, parameters: [
            .contentID: routeId,
            .description: routeName
        ])
    }

    /// The user started turn-by-turn navigation to a place.
    static func logNavigationStarted(placeId: String, placeType: String) {
        AppEvents.shared.logEvent(Custom.startNavigation, parameters: [
            .contentID: placeId,
            .contentType: placeType
        ])
    }

    /// The user played an audio guide.
    static func logAudioGuidePlayed(contentId: String, contentType: String) {
        AppEvents.shared.logEvent(Custom.playAudioGuide, parameters: [
            .contentID: contentId,
            .contentType: contentType
        ])
    }
}
