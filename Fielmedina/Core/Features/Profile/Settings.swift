//
//  Settings.swift
//  Fielmedina
//
//  Created by Aslan on 1/13/26.
//

import SwiftUI
import CoreLocation

struct SettingsView: View {
    struct OfflineCity: Identifiable {
        let id: String
        let name: String
        let coordinate: CLLocationCoordinate2D
        let radius: CLLocationDistance
        let cityId: Int32
    }
    
    enum OfflineRegionStatus: Equatable {
        case notDownloaded
        case downloading(Double)
        case downloaded
        case failed(String)
    }
    
    @State private var offlineCities: [OfflineCity] = []
    @State private var isOnline: Bool = NetworkMonitor.shared.isConnected
    
    @State private var regionStatus: [String: OfflineRegionStatus] = [:]
    @State private var isLoadingRegions = true
    @State private var isOfflineReady = OfflineContentPrefetcher.shared.isComplete
    @State private var offlineStatus = OfflineContentPrefetcher.shared.status
    @State private var offlineProgress = OfflineContentPrefetcher.shared.progress
    @State private var fcmToken: String? = FirebaseUtils.getSavedToken()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                
                offlineSection
                
                if let token = fcmToken, token.count >= 6 {
                    HStack(spacing: 4) {
                        Text("ID :")
                            .font(.caption)
                            .foregroundStyle(.secondary.opacity(0.8))
                        Text(token.suffix(6).uppercased())
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle(String(localized: "Offline Maps"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .refreshable {
            await fetchOfflineCities()
            await loadExistingRegions()
        }
        .task {
            await fetchOfflineCities()
            await loadExistingRegions()
            OfflineContentPrefetcher.shared.prefetchIfNeeded()
            offlineStatus = OfflineContentPrefetcher.shared.status
            offlineProgress = OfflineContentPrefetcher.shared.progress
        }
        .onReceive(NotificationCenter.default.publisher(for: .networkStatusChanged)) { notification in
            isOnline = (notification.userInfo?["isConnected"] as? Bool) ?? NetworkMonitor.shared.isConnected
        }
        .onReceive(NotificationCenter.default.publisher(for: .offlinePrefetchCompleted)) { _ in
            isOfflineReady = true
            offlineProgress = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: .offlinePrefetchStatusChanged)) { notification in
            if let status = notification.object as? OfflineContentPrefetcher.Status {
                offlineStatus = status
            } else {
                offlineStatus = OfflineContentPrefetcher.shared.status
            }
            isOfflineReady = OfflineContentPrefetcher.shared.isComplete
            offlineProgress = OfflineContentPrefetcher.shared.progress
        }
        .onReceive(NotificationCenter.default.publisher(for: .offlinePrefetchProgressChanged)) { notification in
            if let progress = notification.object as? Double {
                offlineProgress = progress
            } else {
                offlineProgress = OfflineContentPrefetcher.shared.progress
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tileRegionProgressChanged)) { notification in
            guard let userInfo = notification.userInfo,
                  let id = userInfo["id"] as? String,
                  let progress = userInfo["progress"] as? Double else { return }
            withAnimation(.linear) {
                regionStatus[id] = .downloading(progress)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tileRegionCompleted)) { notification in
            guard let id = notification.userInfo?["id"] as? String else { return }
            regionStatus[id] = .downloaded
        }
        .onReceive(NotificationCenter.default.publisher(for: .tileRegionFailed)) { notification in
            guard let id = notification.userInfo?["id"] as? String,
                  let error = notification.userInfo?["error"] as? String else { return }
            regionStatus[id] = .failed(error)
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Download city medinas to use maps and navigation without internet."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(offlineStatusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if shouldShowOfflineProgress {
                ProgressView(value: offlineProgress)
                    .tint(Color(red: 0.88, green: 0.43, blue: 0.20))
            }
        }
    }

    private var offlineStatusMessage: String {
        if isOfflineReady {
            return String(localized: "Offline content ready. You can use the app without internet.")
        }

        switch offlineStatus {
        case .waitingForLocation:
            return String(localized: "Waiting for location to download offline content.")
        case .permissionDenied:
            return String(localized: "Enable location permissions to download offline content.")
        case .failed(let error):
            return String(localized: "Download failed: \(error). We'll retry shortly.")
        case .downloading(let message):
            return message
        case .idle, .completed:
            return String(localized: "Offline content is preparing in the background.")
        }
    }

    private var shouldShowOfflineProgress: Bool {
        switch offlineStatus {
        case .downloading:
            return !isOfflineReady
        case .waitingForLocation, .permissionDenied, .failed, .idle, .completed:
            return false
        }
    }
    
    private var offlineBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(String(localized: "Connect to the internet to download offline medinas"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var offlineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !isOnline {
                offlineBanner
            }

            HStack {
                Text(String(localized: "AVAILABLE MEDINAS").uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(offlineCities.count) \(String(localized: "regions"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(offlineCities.enumerated()), id: \.element.id) { index, city in
                    OfflineRegionCard(
                        city: city,
                        status: regionStatus[city.id] ?? .notDownloaded,
                        isLoadingRegions: isLoadingRegions,
                        isOnline: isOnline,
                        onDownload: { download(city) },
                        onRemove: { remove(city) }
                    )
                    
                    if index < offlineCities.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    private func download(_ city: OfflineCity) {
        regionStatus[city.id] = .downloading(0.01)
        OfflineMapsManager.shared.downloadRegion(
            id: city.id,
            name: city.name,
            coordinate: city.coordinate,
            radius: city.radius
        ) { progress in
            withAnimation(.linear) {
                regionStatus[city.id] = .downloading(progress)
            }
        } completion: { result in
            switch result {
            case .success:
                regionStatus[city.id] = .downloaded
                OfflineCityDataStore.shared.markCityDataDownloaded(cityId: city.cityId, regionId: city.id)
                OfflineMapsManager.recordRegionGeometry(
                    regionId: city.id,
                    latitude: city.coordinate.latitude,
                    longitude: city.coordinate.longitude,
                    radius: city.radius
                )
                OfflineContentPrefetcher.shared.prefetchForCity(city.cityId)
            case .failure(let error):
                regionStatus[city.id] = .failed(error.localizedDescription)
            }
        }
    }
    
    private func remove(_ city: OfflineCity) {
        OfflineMapsManager.shared.removeRegion(id: city.id) { _ in
            regionStatus[city.id] = .notDownloaded
            OfflineCityDataStore.shared.removeCityData(for: city.id)
        }
    }
    
    private func loadExistingRegions() async {
        isLoadingRegions = true
        OfflineMapsManager.shared.fetchDownloadedRegionIds { regionIds in
            let active = OfflineMapsManager.shared.activeDownloads
            
            for city in offlineCities {
                if let progress = active[city.id] {
                    regionStatus[city.id] = .downloading(progress)
                } else if regionIds.contains(city.id) {
                    regionStatus[city.id] = .downloaded
                } else {
                    regionStatus[city.id] = .notDownloaded
                }
            }
            isLoadingRegions = false
        }
    }
    
    private func fetchOfflineCities() async {
        do {
            let query = FielmedinaAPI.GetOfflineCitiesQuery(isActive: .some(true))
            let data = try await Network.shared.apollo.fetchNetworkAware(query: query)
            let fetchedCities = data.offlineCities.compactMap { city -> OfflineCity? in
                guard let lat = Double(city.latitude),
                      let lon = Double(city.longitude),
                      let cityIdStr = city.city?.id, let cityId = Int32(cityIdStr) else {
                    return nil
                }
                return OfflineCity(
                    id: city.regionId,
                    name: city.name,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    radius: city.radius,
                    cityId: cityId
                )
            }
            guard !fetchedCities.isEmpty else { return }
            self.offlineCities = fetchedCities
            let cached = fetchedCities.map {
                OfflineCityDataStore.CachedCity(
                    id: $0.id,
                    cityId: $0.cityId,
                    name: $0.name,
                    latitude: $0.coordinate.latitude,
                    longitude: $0.coordinate.longitude,
                    radius: $0.radius
                )
            }
            OfflineCityDataStore.shared.updateCitiesCache(cities: cached)
        } catch {
            print("Error fetching offline cities: \(error)")
        }
    }
}

private struct OfflineRegionCard: View {
    let city: SettingsView.OfflineCity
    let status: SettingsView.OfflineRegionStatus
    let isLoadingRegions: Bool
    let isOnline: Bool
    let onDownload: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(city.name)
                        .font(.headline)
                    Text(String(localized: "Offline navigation + maps"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 8)
                
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
            if case .downloading(let progress) = status {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(String(localized: "Downloading..."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(progress.formatted(.percent.precision(.fractionLength(0))))
                            .font(.caption.bold())
                            .foregroundColor(Color(red: 0.88, green: 0.43, blue: 0.20))
                    }
                    
                    ProgressView(value: progress)
                        .tint(Color(red: 0.88, green: 0.43, blue: 0.20))
                        .scaleEffect(x: 1, y: 0.8, anchor: .center)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .redacted(reason: isLoadingRegions ? .placeholder : [])
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 8) {
            switch status {
            case .notDownloaded, .failed:
                Text(String(localized: "Not downloaded"))
                    .font(.caption.bold())
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                
                Button {
                    onDownload()
                } label: {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isOnline ? .white : .white.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .background(
                            isOnline
                                ? Color(red: 0.88, green: 0.43, blue: 0.20)
                                : Color(.systemGray3)
                        )
                        .clipShape(Circle())
                }
                .disabled(!isOnline)
                
            case .downloading:
                Text(String(localized: "Downloading..."))
                    .font(.caption.bold())
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundColor(Color(red: 0.88, green: 0.43, blue: 0.20))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.88, green: 0.43, blue: 0.20).opacity(0.15))
                    .clipShape(Capsule())
                
            case .downloaded:
                Text(String(localized: "Downloaded"))
                    .font(.caption.bold())
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.4))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.1, green: 0.6, blue: 0.4).opacity(0.15))
                    .clipShape(Capsule())
                
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.red.opacity(0.8))
                        .clipShape(Circle())
                }
            }
        }
    }
}
