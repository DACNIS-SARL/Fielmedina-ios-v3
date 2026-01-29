# AGENTS.md - Technical Briefing for AI Assistants

This file provides critical technical context and constraints for AI coding assistants working on the Fielmedina iOS project. **Prioritize these rules over general suggestions.**

## 1. Quick Operations

- **Build Target**: iOS 18+ (Xcode 16).
- **Codegen**: `./apollo-ios-cli generate` (Run after ANY `.graphql` file change).
- **Schema**: `./apollo-ios-cli fetch-schema` (Sync with backend).
- **Testing**: `xcodebuild test -scheme Fielmedina -destination 'platform=iOS Simulator,name=iPhone 16'`.

## 2. Core Architectural Rules (DO NOT DEVIATE)

1. **GraphQL Namespace**: All generated types are in the `FielmedinaAPI` namespace. **DO NOT** use `import FielmedinaAPI`. Access via dot notation (e.g., `FielmedinaAPI.GetEventsQuery`).
2. **Model Decoupling**: **NEVER** pass `FielmedinaAPI` types directly to SwiftUI Views. Always map them to domain models in `Services/API/Models/`.
3. **State Management**: Use the `@Observable` macro (iOS 17+). Avoid `ObservableObject` unless interacting with legacy libraries. Use `@State` in Views for ViewModel instantiation.
4. **Concurrency**: Use `async/await` and `TaskGroup`. **NEVER** use `completionHandlers` for networking. Ensure UI updates happen on `@MainActor`.
5. **Security**: **Sensitive keys/tokens MUST go in `KeychainStore.swift`.** Non-sensitive state goes in `UserDefaults`.

## 3. UI & Asset Standards

- **Images**: **ALWAYS** use `FielmedinaImage`. It handles local fallback assets and remote URL loading logic. Do not use `AsyncImage` directly.
- **Hiking Navigation**:
  - `HikingNavigator.swift`: Business logic, session state, persistence.
  - `MapboxHikingNavigationView.swift`: UIKit bridge, map rendering, overlays.
- **Offline Logic**: Use `OfflineMapsManager.shared.activeDownloads` to verify region status. Do not trust `allTileRegions` alone for "Ready" status.

## 4. Implementation Patterns

- **Localization**: Use `String(localized:)` in models. Use `LocalizedStringKey` in UI components. Translations are in `Localizable.xcstrings`.
- **Parallel Fetching**: In ViewModels, fetch multiple independent datasets (e.g., Events and Ads) concurrently using `withThrowingTaskGroup`.
- **API Security**: All GraphQL requests are intercepted by `SecurityHeaderInterceptor` to inject `X-Device-ID`.

## 5. Invariants (Common Pitfalls)

- **Namespace Collision**: If you get a "not found" error for a GraphQL type, run codegen.
- **URL Errors**: If using a local asset name, `URL(string:)` will return nil or error -1002. Use `FielmedinaImage`.
- **Location Sync**: Always use `LocationManager.shared` to ensure consistent location updates across the app.

---
*Context valid as of Feb 2026. Maintainer: Muhammad Aslan* 🚀
