# Fielmedina iOS App - 2026 Architecture

## Overview

Fielmedina is a modern iOS application built with SwiftUI, focusing on cultural events, locations, and hiking experiences in Tunisia. The app utilizes Apollo GraphQL for live data and is designed with a "Concurrency-First" approach using Swift 6.

## Project Structure

```bash
Fielmedina/
├── App/
│   └── FielmedinaApp.swift           # Application Entry Point & Delegate
├── Components/                       # Reusable UI Components
│   └── Ui/
│       ├── Events/                   # EventCard, EventItem, CarouselList
│       ├── Locations/                # LocationCard, LocationItem, CarouselListLocations
│       ├── Tips/                     # TipsCarousel, TipItem
│       ├── Hiking/                   # HikingMetricView, RouteOverlays
│       ├── FielmedinaImage.swift     # Dual-source (URL/Local) Image Component
│       └── SettingsButton.swift
├── Core/
│   ├── Features/                     # Main Feature Views
│   │   ├── Home/                     # Landing & Discovery
│   │   ├── Events/                   # Event Browsing & Details
│   │   ├── Locations/                # POI Discovery
│   │   ├── Hiking/                   # Hiking List, Navigator, Mapbox Bridge
│   │   ├── Map/                      # Global Exploration Map
│   │   ├── Transports/               # Public Transport Schedules
│   │   ├── AR/                       # Augmented Reality Experiences
│   │   ├── Profile/                  # Settings, Preferences, Offline Maps
│   │   └── Utils/                    # View Modifiers & Logic Helpers
│   ├── Network/
│   │   └── GraphQL/                  # Apollo Schema & .graphql Operations
│   ├── Security/                     # KeychainStore & API Interceptors
│   ├── Notifications/                # Push & Local Location Management
│   └── Extensions/                   # Native Type Extensions (Date, String, etc.)
├── Services/
│   ├── API/
│   │   ├── Models/                   # Pure Swift Domain Models (Decoupled from GraphQL)
│   │   ├── Sync/                     # Device Registration & Logic Sync
│   │   ├── data/                     # Mock data & Static providers
│   │   └── ...Service.swift          # Feature-specific API managers
│   ├── Offline/                      # Mapbox TileStore & Region Management
│   ├── Cache/                        # URLCache Config & Content Prefetcher
│   ├── Navigation/                   # Mapbox Routing Provider Stores
│   ├── Analytics/                    # Firebase & Crashlytics Integration
│   └── Locale/                       # Multilingual Logic (EN/FR)
└── Assets.xcassets                   # Thematic Media & SF Symbol Markers
```

## GraphQL & Data Flow

### Apollo iOS 2.0 Integration

The app uses the latest Apollo iOS 2.0.4 framework.

- **Code Generation**: Driven by `apollo-ios-cli`.
- **Namespace**: All generated types are under the `FielmedinaAPI` namespace.
- **Workflow**: Edit `.graphql` files in `Core/Network/GraphQL` and run `./apollo-ios-cli generate`.

### Live Data Services

Data is fetched asynchronously using native Swift concurrency.

- **EventService**: Centralized fetcher for individual and city-based events.
- **FielmedinaImage**: A smart image component that handles both remote URLs and local fallback assets (e.g., `event-e`).

## Architecture Patterns

### 1. Swift 6 Concurrency

We use `async/await` and `Actors` throughout the service layer to ensure thread safety and smooth UI performance.

### 2. Observation Framework

State management is handled using the modern `@Observable` macro (iOS 17+), replacing the legacy `ObservableObject` pattern.

### 3. Localization

The app supports English and French using modern **String Catalogs** (`.xcstrings`). Text is dynamically selected based on the user's system language via `displayName` properties in models.

### 4. Security & Persistence

- **KeychainStore**: Sensitive data like `deviceUUID` and `fcmToken` are stored securely in the iOS Keychain.
- **Security Interceptors**: API requests automatically include security headers (`X-Device-ID`) via Apollo interceptors.

### 5. Offline Mobility

- **OfflineMapsManager**: Manages Mapbox style packs and tile regions. Tracks active downloads and notifies the UI in real-time.
- **OfflineContentPrefetcher**: High-performance background prefetcher for Apollo data and media assets.
- **Hybrid Metrics**: Hiking metrics (duration/distance) automatically switch to the Navigation SDK's offline routing engine when disconnected.

## How to Build

1. **Dependencies**: Managed via Swift Package Manager (Apollo, Firebase, Mapbox).
2. **Configuration**: Ensure `GoogleService-Info.plist` is present.
3. **GraphQL**: Run `./apollo-ios-cli generate` to ensure all API models are up to date.
4. **Build**: Use Xcode 16+ / iOS 18+ Target.

## Developer Guide

### How to add a new GraphQL Query

1. **Add Operation**: Create or edit a `.graphql` file in `Core/Network/GraphQL/Queries/`.
2. **Generate Code**: Run the following command in the project root:

    ```bash
    ./apollo-ios-cli generate
    ```

3. **Create Service**: Add a new service in `Services/API/` to wrap the generated query with `async/await`.
4. **Map to Model**: Ensure you map the generated `FielmedinaAPI` types to a domain model in `Services/API/Models/`.

### How to add a new UI Feature

1. **Model**: Define your data structure in `Services/API/Models/`. Use `String(localized:)` for static text.
2. **ViewModel**: Create a `FeatureViewModel.swift` using the `@Observable` macro. Use `withThrowingTaskGroup` if fetching from multiple sources.
3. **View**: Create a new folder in `Core/Features/` for your feature. Bind the View to the ViewModel using `@State`.

### Localization Workflow

1. **In Code**: Use `String(localized: "Key")` for strings in logic/models.
2. **In Components**: Use `LocalizedStringKey` for properties that will be passed into `Text()`.
3. **In Catalog**: Open `Localizable.xcstrings` and provide the French (fr) translation. Xcode will auto-extract keys if you use the modern APIs above.

## Architecture Highlights

- **Namespace**: GraphQL generated code is inside the `FielmedinaAPI` namespace. Never `import` it; access via `FielmedinaAPI.QueryName`.
- **Parallel Loading**: Always use `TaskGroup` or `withThrowingTaskGroup` in ViewModels when loading multiple data types (e.g., Events + Locations) to ensure high performance.
- **Images**: Always use `FielmedinaImage` instead of `AsyncImage` to handle local assets and remote URLs robustly.
- **Navigation Logic**: Keep AI-driven navigation logic in `HikingNavigator` (SwiftUI) and map visualization in `MapboxHikingNavigationView` (UIKit Bridge).
- **Offline Readiness**: Use `OfflineMapsManager.shared.activeDownloads` to check for incomplete regions before marking a city as "Ready".

## Troubleshooting

- **Missing Module Error**: If you see `No such module 'FielmedinaAPI'`, remove the `import FielmedinaAPI` statement. The code is embedded in the main target.
- **URL Error -1002**: This happens if a local asset name is passed to a raw `URL` initializer. Use `FielmedinaImage` to fix this.

---
*Developed by Aslan - 2026* 🚀
