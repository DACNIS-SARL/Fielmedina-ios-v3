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
    }
    
    enum OfflineRegionStatus: Equatable {
        case notDownloaded
        case downloading(Double)
        case downloaded
        case failed(String)
    }
    
    private let offlineCities: [OfflineCity] = [
        OfflineCity(id: "sousse_medina", name: "Sousse Medina", coordinate: CLLocationCoordinate2D(latitude: 35.825892, longitude: 10.637448), radius: 2000),
        OfflineCity(id: "monastir_medina", name: "Monastir Medina", coordinate: CLLocationCoordinate2D(latitude: 35.7780, longitude: 10.8262), radius: 2000),
        OfflineCity(id: "tunis_medina", name: "Tunis Medina", coordinate: CLLocationCoordinate2D(latitude: 36.7992, longitude: 10.1706), radius: 2500)
    ]
    
    @State private var regionStatus: [String: OfflineRegionStatus] = [:]
    @State private var isLoadingRegions = true
    @State private var isOfflineReady = OfflineContentPrefetcher.shared.isComplete
    @State private var offlineStatus = OfflineContentPrefetcher.shared.status
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                
                offlineSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await loadExistingRegions()
            OfflineContentPrefetcher.shared.prefetchIfNeeded()
            offlineStatus = OfflineContentPrefetcher.shared.status
        }
        .onReceive(NotificationCenter.default.publisher(for: .offlinePrefetchCompleted)) { _ in
            isOfflineReady = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .offlinePrefetchStatusChanged)) { notification in
            if let status = notification.object as? OfflineContentPrefetcher.Status {
                offlineStatus = status
            } else {
                offlineStatus = OfflineContentPrefetcher.shared.status
            }
            isOfflineReady = OfflineContentPrefetcher.shared.isComplete
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Offline Maps")
                .font(.title2.bold())
            Text("Download city medinas to use maps and navigation without internet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(offlineStatusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var offlineStatusMessage: String {
        if isOfflineReady {
            return "Offline content ready. You can use the app without internet."
        }

        switch offlineStatus {
        case .waitingForLocation:
            return "Waiting for location to download offline content."
        case .permissionDenied:
            return "Enable location permissions to download offline content."
        case .failed:
            return "Offline content download failed. We'll retry shortly."
        case .downloading:
            return "Offline content is downloading in the background while you explore."
        case .idle, .completed:
            return "Offline content is preparing in the background."
        }
    }
    
    private var offlineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(offlineCities) { city in
                OfflineRegionCard(
                    city: city,
                    status: regionStatus[city.id] ?? .notDownloaded,
                    isLoadingRegions: isLoadingRegions,
                    onDownload: {
                        download(city)
                    },
                    onRemove: {
                        remove(city)
                    }
                )
            }
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
            case .failure(let error):
                regionStatus[city.id] = .failed(error.localizedDescription)
            }
        }
    }
    
    private func remove(_ city: OfflineCity) {
        OfflineMapsManager.shared.removeRegion(id: city.id) { _ in
            regionStatus[city.id] = .notDownloaded
        }
    }
    
    private func loadExistingRegions() async {
        isLoadingRegions = true
        OfflineMapsManager.shared.fetchDownloadedRegionIds { regionIds in
            for city in offlineCities {
                regionStatus[city.id] = regionIds.contains(city.id) ? .downloaded : .notDownloaded
            }
            isLoadingRegions = false
        }
    }
}

private struct OfflineRegionCard: View {
    let city: SettingsView.OfflineCity
    let status: SettingsView.OfflineRegionStatus
    let isLoadingRegions: Bool
    let onDownload: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(city.name)
                        .font(.headline)
                    Text("Offline navigation + maps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge
            }
            
            if case .downloading(let progress) = status {
                ProgressView(value: progress)
                    .tint(Color(red: 0.72, green: 0.41, blue: 0.25))
            }
            
            HStack(spacing: 12) {
                switch status {
                case .notDownloaded, .failed:
                    Button("Download") {
                        onDownload()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.72, green: 0.41, blue: 0.25))
                case .downloading:
                    Button("Downloading…") { }
                        .buttonStyle(.bordered)
                        .disabled(true)
                case .downloaded:
                    Button("Remove") {
                        onRemove()
                    }
                    .buttonStyle(.bordered)
                }
                
                if case .failed(let message) = status {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .redacted(reason: isLoadingRegions ? .placeholder : [])
    }
    
    private var statusBadge: some View {
        switch status {
        case .downloaded:
            return Text("Ready")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .clipShape(Capsule())
        case .downloading:
            return Text("Downloading")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .clipShape(Capsule())
        case .failed:
            return Text("Failed")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.2))
                .clipShape(Capsule())
        case .notDownloaded:
            return Text("Not downloaded")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .clipShape(Capsule())
        }
    }
}

#Preview {
    SettingsView()
}
