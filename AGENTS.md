# AGENTS.md - Fielmedina iOS

## Build & Test Commands

- **Build**: Open `Fielmedina.xcodeproj` in Xcode 16+, target iOS 18+
- **GraphQL Codegen**: `./apollo-ios-cli generate` (run after editing `.graphql` files)
- **Schema Download**: `./apollo-ios-cli fetch-schema`
- **Run Tests**: `xcodebuild test -scheme Fielmedina -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Single Test**: `xcodebuild test -scheme Fielmedina -only-testing:FielmedinaTests/TestClassName/testMethodName`

## Architecture

- **SwiftUI + Swift 6** with async/await concurrency; uses `@Observable` macro (iOS 17+)
- **Apollo iOS 2.0**: GraphQL queries in `Core/Network/GraphQL/`; generated types in `FielmedinaAPI` namespace (embedded in target, never `import FielmedinaAPI`)
- **Services**: Singleton pattern (`Service.shared`), wrap Apollo queries with async/await
- **Offline**: `OfflineMapsManager` for Mapbox navigation tiles; `OfflineContentPrefetcher` for API/Media caching
- **Security**: `KeychainStore` for unique device IDs and sensitive tokens; `SecurityHeaderInterceptor` for API authentication
- **Dependencies**: SPM (Apollo, Firebase, Mapbox); requires `GoogleService-Info.plist`

## Code Style

- Use `async/await` and `TaskGroup` for parallel loading; never block main thread
- Use `FielmedinaImage` instead of `AsyncImage` for robust image handling
- Navigation Logic: Keep business logic in `HikingNavigator.swift` and Mapbox UIKit bridging in `MapboxHikingNavigationView.swift`
- Localization: `String(localized:)` in code, `LocalizedStringKey` in SwiftUI; translations in `Localizable.xcstrings`
- Models have `displayName` computed properties for EN/FR locale switching
- Map GraphQL types (`FielmedinaAPI.*`) to domain models in `Services/API/Models/`
- ViewModels use `@Observable` macro; Views bind via `@State`
