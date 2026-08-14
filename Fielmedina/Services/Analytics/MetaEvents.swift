//
//  MetaEvents.swift
//  Fielmedina
//
//  Meta (Facebook/Instagram) App Events — the measurement layer Ads Manager
//  optimises against.
//
//  Why this file exists
//  --------------------
//  `FacebookCore` was linked in the Xcode project and `FacebookAppID` /
//  `FacebookClientToken` were present in Info.plist, but the SDK was never
//  initialised in code. A linked-but-uninitialised SDK sends **nothing** — not even
//  the automatic install/activate event — so Meta could not see a single iOS install
//  or action, and every campaign was optimising against an empty signal.
//
//  The three things Meta measurement needs, all of which now live here or in
//  Info.plist:
//   1. SDK initialisation        → `initializeSDK(...)` (called from AppDelegate)
//   2. SKAdNetwork registration  → `SKAdNetworkItems` in Info.plist (Meta's two IDs)
//   3. ATT authorisation         → `requestTrackingAuthorizationIfNeeded()`
//
//  Event names are intentionally identical to the Android implementation
//  (`core/analytics/MetaEvents.kt`). Ads Manager optimises per event *name*: if the
//  two platforms emit different names, the same campaign cannot optimise across
//  both, which is a silent and expensive way to waste budget.
//
//  This is additive — it does not replace Firebase Analytics (`FirebaseUtils`).
//  Firebase is for product analytics; Meta is for ad attribution. Both are needed.
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

    /// Shows the ATT prompt once, and only once the user has finished onboarding.
    ///
    /// Deliberately *not* called at cold start: iOS silently returns
    /// `.notDetermined` if the prompt is requested while the app is not yet active,
    /// and asking during onboarding — on top of the notification and location
    /// prompts — measurably lowers opt-in.
    ///
    /// Asking is all this has to do. There is deliberately no
    /// `Settings.isAdvertiserTrackingEnabled` call: that setter is deprecated and
    /// ignored on iOS 17+, and our deployment target is 18.6, so FBSDK v18 reads
    /// `ATTrackingManager.trackingAuthorizationStatus` itself on every device that
    /// can run this app. Setting it would be dead code that only looks meaningful.
    static func requestTrackingAuthorizationIfNeeded() async {
        guard !hasRequestedTracking else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            hasRequestedTracking = true   // already answered in an earlier session
            return
        }

        let status = await ATTrackingManager.requestTrackingAuthorization()

        // Only burn the one-shot flag if the system actually presented the prompt.
        // Requesting while the app is not yet fully active returns `.notDetermined`
        // without showing anything — retrying on the next foreground is the
        // difference between asking the user and never asking at all.
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

    /// A global search was performed. Meta's `Search`.
    static func logSearch(query: String, resultCount: Int) {
        AppEvents.shared.logEvent(.searched, parameters: [
            .searchString: query,
            .success: resultCount > 0 ? 1 : 0
        ])
    }

    /// Onboarding finished. Meta's `CompletedTutorial`.
    static func logOnboardingCompleted() {
        AppEvents.shared.logEvent(.completedTutorial, parameters: [.success: 1])
    }

    /// An offline map region finished downloading — the real activation moment for
    /// this app, since it is what makes the guide usable inside a medina.
    /// Mapped to Meta's `UnlockedAchievement` so it can be used as a standard
    /// optimisation event.
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
