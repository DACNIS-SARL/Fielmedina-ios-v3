import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class AllMerchantsModel {

    private(set) var merchants: [Merchant] = []
    private(set) var displayedMerchants: [Merchant] = []
    private(set) var categories: [MerchantCategory] = []
    private(set) var availableCities: [MerchantCity] = []
    private(set) var isLoading = true
    private(set) var isRefreshing = false
    private(set) var isLoadingNextPage = false
    private(set) var errorMessage: String?
    private(set) var hasMoreData = true
    private(set) var isConnected = NetworkMonitor.shared.isConnected

    var selectedCityId: String? {
        didSet {
            guard oldValue != selectedCityId else { return }
            recomputeDisplayedMerchants()
        }
    }

    var selectedCategoryId: String? {
        didSet {
            guard oldValue != selectedCategoryId else { return }
            recomputeDisplayedMerchants()
        }
    }

    private let pageSize: Int32 = 50
    private let paginationPrefetchAhead = 3
    private let offlineSnapshotLimit: Int32 = 200

    private let merchantService: MerchantService

    private var userCoordinate: CLLocationCoordinate2D?
    private var userLocationBucket: String?

    @ObservationIgnored nonisolated(unsafe) private var networkObserver: NSObjectProtocol?

    init(merchantService: MerchantService = .shared) {
        self.merchantService = merchantService

        networkObserver = NotificationCenter.default.addObserver(
            forName: .networkStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let connected = notification.userInfo?["isConnected"] as? Bool else { return }
            Task { @MainActor [weak self] in
                self?.handleConnectivityChange(connected)
            }
        }
    }

    deinit {
        if let networkObserver {
            NotificationCenter.default.removeObserver(networkObserver)
        }
    }

    var isFiltering: Bool {
        selectedCityId != nil || selectedCategoryId != nil
    }

    var cityOptions: [FilterMenuOption] {
        [FilterMenuOption(id: nil, label: String(localized: "All Regions"))]
            + availableCities.map { FilterMenuOption(id: $0.id, label: $0.displayName) }
    }

    var categoryOptions: [FilterMenuOption] {
        [FilterMenuOption(id: nil, label: String(localized: "All Picks"))]
            + categories.map { FilterMenuOption(id: $0.id, label: $0.displayName) }
    }

    var emptyStateTitle: String {
        isFiltering
            ? String(localized: "No Picks Found")
            : String(localized: "No Picks Yet")
    }

    var emptyStateMessage: String {
        isFiltering
            ? String(localized: "There are no picks for this filter yet.\nCheck back soon!")
            : String(localized: "There are no picks available yet.\nCheck back soon!")
    }

    func isNearEnd(_ merchant: Merchant) -> Bool {
        guard let index = displayedMerchants.firstIndex(where: { $0.id == merchant.id }) else {
            return false
        }
        return index >= displayedMerchants.count - paginationPrefetchAhead
    }

    func updateUserLocation(_ coordinate: CLLocationCoordinate2D?) {
        userCoordinate = coordinate
        let bucket = coordinate.map { "\(Int($0.latitude * 1000)),\(Int($0.longitude * 1000))" }
        guard bucket != userLocationBucket else { return }
        userLocationBucket = bucket
        recomputeDisplayedMerchants()
    }

    private func handleConnectivityChange(_ connected: Bool) {
        let wasOffline = !isConnected
        isConnected = connected
        if connected && wasOffline {
            Task { await refreshFromNetwork() }
        }
    }

    func loadData(forceRefresh: Bool = false) async {
        if merchants.isEmpty {
            isLoading = true
        }
        errorMessage = nil

        let previousMerchants = merchants

        await loadMerchants(forceRefresh: forceRefresh)

        if merchants.isEmpty && !previousMerchants.isEmpty {
            merchants = previousMerchants
        }

        refreshFilterOptions()
        isLoading = false
        recomputeDisplayedMerchants()
    }

    func refreshFromNetwork() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        await loadData(forceRefresh: true)
    }

    func loadNextPage() async {
        guard isConnected, hasMoreData, !isLoadingNextPage, !isLoading, !isRefreshing else { return }
        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        do {
            let fetched = try await merchantService.fetchMerchants(
                cityId: nil,
                categoryId: nil,
                limit: pageSize,
                offset: Int32(merchants.count)
            )
            var seen = Set(merchants.map(\.id))
            let newItems = fetched.filter { seen.insert($0.id).inserted }
            merchants.append(contentsOf: newItems)

            hasMoreData = fetched.count >= Int(pageSize)
            refreshFilterOptions()
            recomputeDisplayedMerchants()
        } catch {
        }
    }

    private func loadMerchants(forceRefresh: Bool = false) async {
        errorMessage = nil

        do {
            let limit = isConnected ? pageSize : offlineSnapshotLimit

            let fetchedMerchants = try await merchantService.fetchMerchants(
                cityId: nil,
                categoryId: nil,
                limit: limit,
                offset: 0,
                forceRefresh: forceRefresh
            )

            merchants = fetchedMerchants
            hasMoreData = isConnected && fetchedMerchants.count >= Int(limit)
        } catch {
            if merchants.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func refreshFilterOptions() {
        var seenCategories = Set<String>()
        let derivedCategories = merchants
            .compactMap(\.category)
            .filter { seenCategories.insert($0.id).inserted }
            .sorted { $0.displayName < $1.displayName }
        if !derivedCategories.isEmpty {
            categories = derivedCategories
        }

        var seenCities = Set<String>()
        let derivedCities = merchants
            .compactMap(\.city)
            .filter { !$0.displayName.isEmpty && seenCities.insert($0.id).inserted }
            .sorted { $0.displayName < $1.displayName }
        if !derivedCities.isEmpty {
            availableCities = derivedCities
        }
    }

    private func recomputeDisplayedMerchants() {
        var result = merchants

        if let cityId = selectedCityId {
            result = result.filter { $0.city?.id == cityId }
        }
        if let categoryId = selectedCategoryId {
            result = result.filter { $0.category?.id == categoryId }
        }

        if let userCoordinate {
            let userLoc = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
            result = result
                .map { merchant -> (merchant: Merchant, distance: CLLocationDistance) in
                    let candidate = CLLocation(
                        latitude: merchant.latitude ?? 0.0,
                        longitude: merchant.longitude ?? 0.0
                    )
                    return (merchant, candidate.distance(from: userLoc))
                }
                .sorted { $0.distance < $1.distance }
                .map(\.merchant)
        }

        displayedMerchants = result
    }
}
