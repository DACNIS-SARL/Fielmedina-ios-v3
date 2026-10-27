import Foundation
import StoreKit
import UIKit

enum AppReviewPrompter {
    static let writeReviewURL = URL(string: "https://apps.apple.com/app/id6751167445?action=write-review")!

    private static let activeDaysKey = "review_active_days"
    private static let lastActiveDayKey = "review_last_active_day"
    private static let significantEventsKey = "review_significant_events"
    private static let pendingKey = "review_pending_since_last_request"
    private static let lastRequestAtKey = "review_last_request_at"
    private static let lastRequestVersionKey = "review_last_request_version"
    private static let minimumActiveDays = 3
    private static let minimumSignificantEvents = 2
    private static let minimumIntervalBetweenRequests: TimeInterval = 120 * 24 * 60 * 60

    static func recordActiveDay() {
        let defaults = UserDefaults.standard
        let today = Int(Date().timeIntervalSince1970 / 86_400)
        guard defaults.object(forKey: lastActiveDayKey) as? Int != today else { return }
        defaults.set(today, forKey: lastActiveDayKey)
        defaults.set(defaults.integer(forKey: activeDaysKey) + 1, forKey: activeDaysKey)
    }

    static func recordSignificantEvent() {
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: significantEventsKey) + 1, forKey: significantEventsKey)
        defaults.set(true, forKey: pendingKey)
    }

    static func requestReviewIfAppropriate(after delay: Duration = .zero) {
        Task { @MainActor in
            if delay > .zero {
                try? await Task.sleep(for: delay)
            }
            guard isEligible, let scene = activeWindowScene else { return }
            AppStore.requestReview(in: scene)
            markRequested()
        }
    }

    @MainActor
    private static var activeWindowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }

    private static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    private static var isEligible: Bool {
        let defaults = UserDefaults.standard
        let cooledDown: Bool
        if let lastRequest = defaults.object(forKey: lastRequestAtKey) as? Date {
            cooledDown = Date().timeIntervalSince(lastRequest) >= minimumIntervalBetweenRequests
        } else {
            cooledDown = true
        }
        return defaults.bool(forKey: "hasSeenOnboarding")
            && defaults.bool(forKey: pendingKey)
            && defaults.integer(forKey: activeDaysKey) >= minimumActiveDays
            && defaults.integer(forKey: significantEventsKey) >= minimumSignificantEvents
            && cooledDown
            && defaults.string(forKey: lastRequestVersionKey) != appVersion
            && NetworkMonitor.shared.isConnected
    }

    private static func markRequested() {
        let defaults = UserDefaults.standard
        defaults.set(Date(), forKey: lastRequestAtKey)
        defaults.set(appVersion, forKey: lastRequestVersionKey)
        defaults.set(false, forKey: pendingKey)
    }
}
