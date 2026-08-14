//
//  HomeModel.swift
//  Fielmedina
//
//  Presentation model for Home.
//
//  Deliberately small. Unlike the list screens, Home does not load its own data —
//  each carousel fetches its own — so there was little logic to lift out. What lives
//  here is what genuinely isn't view state:
//
//    • Feature flags for the action buttons (hardcoded today; this is the seam for
//      remote config or entitlement checks later).
//    • Onboarding gating, including the delayed reveal, as a cancellable Task rather
//      than a fire-and-forget `DispatchQueue.asyncAfter` that outlives the screen.
//
//  Deliberately NOT moved here: `navigationPath`, `scrollOffset`, the search overlay
//  flag and its namespace. Those are SwiftUI rendering/navigation state and belong
//  with the View — the same split applied to MapView's camera.
//
//  This is where a personalized/AI recommendations feed should attach: it is loaded
//  data with its own lifecycle, so it belongs in the model, not the View.
//

import Foundation
import Observation

@MainActor
@Observable
final class HomeModel {

    // MARK: - Feature flags

    /// Hardcoded today. Kept here so switching to remote config or an entitlement
    /// check is a change in one place instead of a change to the View.
    private(set) var showTaxiButton = false
    private(set) var showTopPicksButton = true

    // MARK: - Onboarding

    private(set) var showOnboarding = false

    /// Same key the rest of the app uses (`OfflineTileStore` resets it after a tile
    /// migration), so existing users are not re-onboarded.
    private let onboardingKey = "hasSeenOnboarding"
    /// Let the first render settle before the coachmark appears.
    private let onboardingDelay: Duration = .seconds(1.5)

    /// Internal plumbing, never rendered — `@ObservationIgnored` keeps it a plain
    /// stored property, and `nonisolated(unsafe)` lets the non-isolated `deinit`
    /// cancel it.
    @ObservationIgnored nonisolated(unsafe) private var onboardingTask: Task<Void, Never>?

    var hasSeenOnboarding: Bool {
        UserDefaults.standard.bool(forKey: onboardingKey)
    }

    deinit {
        onboardingTask?.cancel()
    }

    /// Schedules the onboarding overlay for first-time users. Cancellable, so
    /// leaving Home before it fires doesn't pop it over another screen.
    func scheduleOnboardingIfNeeded() {
        guard !hasSeenOnboarding, !showOnboarding else { return }
        onboardingTask?.cancel()
        onboardingTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.onboardingDelay)
            guard !Task.isCancelled else { return }
            self.showOnboarding = true
        }
    }

    func completeOnboarding() {
        onboardingTask?.cancel()
        UserDefaults.standard.set(true, forKey: onboardingKey)
        showOnboarding = false
        MetaEvents.logOnboardingCompleted()

        // Ask for tracking permission here, not only on the next `scenePhase`
        // change. On a fresh install the app is *already* active when onboarding
        // ends, so `.active` never fires again this session — waiting for it meant
        // the ATT prompt did not appear until the user backgrounded the app and
        // came back, or relaunched. First-install users simply never saw it.
        Task {
            // Let the coachmark's dismissal animation finish before a system
            // alert covers the screen.
            try? await Task.sleep(for: .milliseconds(600))
            await MetaEvents.requestTrackingAuthorizationIfNeeded()
        }
    }
}
