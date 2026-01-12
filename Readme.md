
# FilMedina iOS App - Modern 2026 Architecture

## Project Structure

```
FilMedinaApp/
├── FilMedinaApp/
│   │
│   ├── App/
│   │   ├── FilMedinaApp.swift              # @main entry, Firebase init
│   │   └── Environment.swift               # Environment variables (API keys, etc)
│   │
│   ├── Core/
│   │   │
│   │   ├── Data/
│   │   │   ├── Models/                     # SwiftData models
│   │   │   │   ├── Location.swift
│   │   │   │   ├── POI.swift
│   │   │   │   ├── Route.swift
│   │   │   │   └── SavedPlace.swift
│   │   │   │
│   │   │   ├── Repositories/               # Data access layer
│   │   │   │   ├── LocationRepository.swift
│   │   │   │   ├── POIRepository.swift
│   │   │   │   └── Protocol/
│   │   │   │       └── Repository.swift
│   │   │   │
│   │   │   └── DataContainer.swift         # SwiftData ModelContainer
│   │   │
│   │   ├── Network/
│   │   │   ├── GraphQL/
│   │   │   │   ├── GraphQLClient.swift
│   │   │   │   ├── Schema/                 # Generated GraphQL types
│   │   │   │   └── Operations/
│   │   │   │       ├── Queries.graphql
│   │   │   │       └── Mutations.graphql
│   │   │   │
│   │   │   ├── HTTPClient.swift
│   │   │   └── NetworkMonitor.swift
│   │   │
│   │   ├── Services/
│   │   │   ├── Location/
│   │   │   │   └── LocationService.swift
│   │   │   │
│   │   │   ├── Sync/
│   │   │   │   ├── SyncEngine.swift        # iOS 17+ background sync
│   │   │   │   └── SyncCoordinator.swift
│   │   │   │
│   │   │   ├── Notifications/
│   │   │   │   └── NotificationService.swift
│   │   │   │
│   │   │   └── Analytics/
│   │   │       └── AnalyticsService.swift
│   │   │
│   │   └── Extensions/
│   │       ├── View+.swift
│   │       ├── CLLocation+.swift
│   │       └── Bundle+.swift
│   │
│   ├── Features/
│   │   │
│   │   ├── Map/
│   │   │   ├── MapFeature.swift            # Feature entry point
│   │   │   ├── MapView.swift
│   │   │   ├── MapViewModel.swift
│   │   │   │
│   │   │   ├── Components/
│   │   │   │   ├── MapControls.swift
│   │   │   │   ├── LocationMarker.swift
│   │   │   │   └── ClusterAnnotation.swift
│   │   │   │
│   │   │   ├── Services/
│   │   │   │   ├── MapboxManager.swift
│   │   │   │   ├── OfflineMapManager.swift
│   │   │   │   └── AINavigationManager.swift
│   │   │   │
│   │   │   └── Models/
│   │   │       └── MapState.swift
│   │   │
│   │   ├── AR/
│   │   │   ├── ARFeature.swift
│   │   │   ├── ARMapView.swift
│   │   │   ├── ARViewModel.swift
│   │   │   │
│   │   │   ├── Components/
│   │   │   │   ├── ARMarkerNode.swift
│   │   │   │   └── AROverlayView.swift
│   │   │   │
│   │   │   └── Services/
│   │   │       └── ARSessionManager.swift
│   │   │
│   │   ├── Search/
│   │   │   ├── SearchFeature.swift
│   │   │   ├── SearchView.swift
│   │   │   ├── SearchViewModel.swift
│   │   │   │
│   │   │   ├── Components/
│   │   │   │   ├── SearchBar.swift
│   │   │   │   ├── SearchResultRow.swift
│   │   │   │   └── FilterSheet.swift
│   │   │   │
│   │   │   └── Services/
│   │   │       └── LocalSearchService.swift
│   │   │
│   │   ├── Navigation/
│   │   │   ├── NavigationFeature.swift
│   │   │   ├── NavigationView.swift
│   │   │   ├── NavigationViewModel.swift
│   │   │   │
│   │   │   └── Components/
│   │   │       ├── RoutePreview.swift
│   │   │       ├── TurnByTurn.swift
│   │   │       └── ETACard.swift
│   │   │
│   │   ├── Profile/
│   │   │   ├── ProfileFeature.swift
│   │   │   ├── ProfileView.swift
│   │   │   ├── ProfileViewModel.swift
│   │   │   │
│   │   │   └── Components/
│   │   │       ├── SavedPlacesList.swift
│   │   │       └── OfflineMapsList.swift
│   │   │
│   │   └── Onboarding/
│   │       ├── OnboardingFlow.swift
│   │       ├── OnboardingView.swift
│   │       └── PermissionsView.swift
│   │
│   ├── DesignSystem/
│   │   ├── Theme/
│   │   │   ├── Colors.swift
│   │   │   ├── Typography.swift
│   │   │   ├── Spacing.swift
│   │   │   └── Shadows.swift
│   │   │
│   │   ├── Components/
│   │   │   ├── Buttons/
│   │   │   │   ├── PrimaryButton.swift
│   │   │   │   ├── SecondaryButton.swift
│   │   │   │   └── IconButton.swift
│   │   │   │
│   │   │   ├── Cards/
│   │   │   │   ├── LocationCard.swift
│   │   │   │   └── POICard.swift
│   │   │   │
│   │   │   ├── Inputs/
│   │   │   │   ├── TextField.swift
│   │   │   │   └── SearchField.swift
│   │   │   │
│   │   │   └── Feedback/
│   │   │       ├── LoadingView.swift
│   │   │       ├── ErrorView.swift
│   │   │       └── EmptyStateView.swift
│   │   │
│   │   └── Modifiers/
│   │       ├── CardStyle.swift
│   │       └── ShimmerEffect.swift
│   │
│   ├── Navigation/
│   │   ├── AppCoordinator.swift            # Navigation coordination
│   │   ├── Routes.swift                    # All app routes
│   │   └── DeepLinkHandler.swift
│   │
│   └── Resources/
│       ├── Assets.xcassets
│       ├── Localizable.xcstrings           # iOS 18 string catalogs
│       └── Info.plist
│
├── FilMedinaAppTests/
│   ├── Unit/
│   │   ├── ViewModels/
│   │   ├── Services/
│   │   └── Repositories/
│   │
│   └── Integration/
│       ├── SyncTests.swift
│       └── OfflineTests.swift
│
├── FilMedinaAppUITests/
│   ├── MapFlowTests.swift
│   ├── SearchFlowTests.swift
│   └── OfflineModeTests.swift
│
└── Package Dependencies/
    ├── apollo-ios (GraphQL)
    ├── firebase-ios-sdk
    └── mapbox-maps-ios
```

---

## Key Architecture Patterns (2026)

### 1. **Swift 6 Concurrency First**
- All async operations use `async/await`
- `@MainActor` for UI updates
- Actor isolation for thread safety
- Structured concurrency with task groups

### 2. **Observation Framework (not Combine)**
```swift
@Observable
class MapViewModel {
    var userLocation: CLLocation?
    var nearbyPOIs: [POI] = []
    var isLoading = false
}
```

### 3. **SwiftData for Persistence**
- Models use `@Model` macro
- Repositories abstract data access
- Queries with `#Predicate` macro

### 4. **Feature-Based Organization**
Each feature is self-contained:
- FeatureView
- FeatureViewModel
- Components (sub-views)
- Services (feature-specific logic)
- Models (view state)

### 5. **Clean Dependency Flow**
```
View → ViewModel → Repository → Data Source (API/SwiftData)
                 ↓
              Services (Location, Sync, etc)
```

### 6. **Modern Navigation**
- NavigationStack + NavigationPath (iOS 16+)
- Deep linking with universal links
- Coordinator pattern for complex flows

---

## Modern iOS 18 Features Used

✅ **SwiftData** - Local persistence
✅ **Observation** - State management (replaces Combine)
✅ **Swift 6** - Strict concurrency
✅ **String Catalogs** - Localization
✅ **Swift Testing** - Modern test framework
✅ **WidgetKit** - Home screen widgets
✅ **App Intents** - Siri shortcuts
✅ **Background Assets** - Smart offline downloads

---

## File Examples

### FilMedinaApp.swift
```swift
import SwiftUI
import FirebaseCore
import MapboxMaps

@main
struct FilMedinaApp: App {
    @State private var dataContainer: ModelContainer
    
    init() {
        // Firebase setup
        FirebaseApp.configure()
        
        // SwiftData setup
        let schema = Schema([
            Location.self,
            POI.self,
            Route.self,
            SavedPlace.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            dataContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        // Mapbox
        MapboxOptions.accessToken = Environment.mapboxToken
    }
    
    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .modelContainer(dataContainer)
        }
    }
}
```

### MapViewModel.swift (Modern @Observable)
```swift
import SwiftUI
import SwiftData
import MapboxMaps

@Observable
@MainActor
class MapViewModel {
    var userLocation: CLLocation?
    var nearbyPOIs: [POI] = []
    var isLoading = false
    var selectedPOI: POI?
    
    private let locationService: LocationService
    private let poiRepository: POIRepository
    private let syncEngine: SyncEngine
    
    init(
        locationService: LocationService,
        poiRepository: POIRepository,
        syncEngine: SyncEngine
    ) {
        self.locationService = locationService
        self.poiRepository = poiRepository
        self.syncEngine = syncEngine
    }
    
    func loadNearbyPOIs() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try local first (offline)
            nearbyPOIs = try await poiRepository.fetchNearby(
                location: userLocation,
                radius: 5000
            )
            
            // Sync in background
            Task.detached {
                await self.syncEngine.syncPOIs()
            }
        } catch {
            print("Error loading POIs: \(error)")
        }
    }
}
```

### SwiftData Model
```swift
import SwiftData
import CoreLocation

@Model
final class POI {
    @Attribute(.unique) var id: String
    var name: String
    var latitude: Double
    var longitude: Double
    var category: String
    var lastSynced: Date
    
    @Relationship(deleteRule: .cascade)
    var images: [POIImage]?
    
    init(id: String, name: String, latitude: Double, longitude: Double, category: String) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.lastSynced = Date()
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
```

---

## Why This Architecture?

### ✅ Offline-First
- SwiftData stores all API responses
- Network monitor switches modes seamlessly
- Background sync when online

### ✅ Testable
- ViewModels are pure logic
- Services are injected (DI)
- Repositories abstract data layer

### ✅ Scalable
- Features are isolated
- Shared components in DesignSystem
- Clear dependency rules

### ✅ Modern Swift
- Swift 6 strict concurrency
- @Observable (not ObservableObject)
- SwiftData (not Core Data)
- String catalogs (not .strings)

### ✅ Maintainable
- Clear file naming
- Feature-based folders
- Single responsibility principle

This is production-ready for 2026! 🚀
