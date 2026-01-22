//
//  HikingView.swift
//  Fielmedina
//
//  Created by Aslan on 1/8/26.
//

import SwiftUI
import CoreLocation
import MapboxDirections

struct HikingView: View {
    @State private var trails: [Hiking] = []
    @State private var metrics: [String: HikingMetrics] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var locationManager = LocationManager()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if isLoading {
                        ProgressView("Loading trails...")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else if let errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundStyle(.red)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task { await loadTrails() }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 20) {
                            ForEach(Array(trails.enumerated()), id: \.element.id) { index, trail in
                                HikingCardView(
                                    hiking: trail,
                                    metrics: metrics[trail.id]
                                )

                                if index < trails.count - 1 {
                                    AdsCarousel(startIndex: index + 1)
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsButton()
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                locationManager.requestPermission()
                locationManager.startUpdatingLocation()
                await loadTrails()
            }
            .onChange(of: locationManager.userLocation) { _, _ in
                Task { await updateMetrics() }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hiking Routes")
                .font(.title)
                .bold()
            Text("Discover Tunisia through guided walking tours")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func loadTrails() async {
        isLoading = true
        errorMessage = nil
        do {
            trails = try await HikingService.shared.fetchHikings(limit: 20)
            await updateMetrics()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func updateMetrics() async {
        guard let userCoordinate = locationManager.userLocation else { return }
        let trailsSnapshot = trails

        let updatedMetrics = await withTaskGroup(of: (String, HikingMetrics?).self) { group in
            for trail in trailsSnapshot {
                group.addTask {
                    let metrics = await calculateMetrics(for: trail, userCoordinate: userCoordinate)
                    return (trail.id, metrics)
                }
            }

            var results: [String: HikingMetrics] = [:]
            for await (id, metrics) in group {
                if let metrics {
                    results[id] = metrics
                }
            }
            return results
        }

        await MainActor.run {
            metrics = updatedMetrics
        }
    }

    private func calculateMetrics(for hiking: Hiking, userCoordinate: CLLocationCoordinate2D) async -> HikingMetrics? {
        let trailWaypoints = hiking.waypoints.map {
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude))
        }
        let waypoints = [Waypoint(coordinate: userCoordinate)] + trailWaypoints
        guard waypoints.count >= 2 else { return nil }

        let options = RouteOptions(waypoints: waypoints, profileIdentifier: .walking)
        options.includesSteps = false
        options.includesAlternativeRoutes = false

        return await withCheckedContinuation { continuation in
            Directions.shared.calculate(options) { result in
                switch result {
                case .success(let response):
                    if let route = response.routes?.first {
                        continuation.resume(returning: HikingMetrics(
                            distance: route.distance,
                            duration: route.expectedTravelTime
                        ))
                    } else {
                        continuation.resume(returning: nil)
                    }
                case .failure:
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

struct HikingMetrics {
    let distance: Double
    let duration: TimeInterval
}

struct HikingCardView: View {
    let hiking: Hiking
    let metrics: HikingMetrics?

    private var locationLabel: String? {
        hiking.cityName
    }

    private var distanceText: String {
        guard let distance = metrics?.distance else { return "--" }
        let kilometers = distance / 1000
        if kilometers >= 1 {
            return String(format: "%.1f km", kilometers)
        }
        return String(format: "%.0f m", distance)
    }

    private var durationText: String {
        guard let duration = metrics?.duration else { return "--" }
        let minutes = Int(duration / 60)
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes) min"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                FielmedinaImage(url: hiking.imageURL, contentMode: .fill)
                    .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 220)
                    .clipped()

                Circle()
                    .fill(Color.pink)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            if let images = hiking.images, images.count > 1 {
                HStack(spacing: 8) {
                    ForEach(Array(images.prefix(4).enumerated()), id: \.offset) { _, image in
                        FielmedinaImage(url: image.displayURL, contentMode: .fill)
                            .frame(width: 64, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(alignment: .top) {
                Text(hiking.displayName)
                    .font(.title3)
                    .bold()

                Spacer()

                if let locationLabel {
                    Text(locationLabel)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                }
            }

            if let description = hiking.displayDescription {
                Text(description.htmlToMarkdown())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            HStack(spacing: 24) {
                HikingMetricView(title: "Distance", value: distanceText)
                HikingMetricView(title: "Duration", value: durationText)
                HikingMetricView(title: "Stops", value: "\(hiking.orderedLocations.count)")
            }
            .padding(.top, 8)

            Button {
                FirebaseUtils.trackButtonTap(buttonName: "start_hiking", screenName: "Hiking")
            } label: {
                Label("Start Hiking", systemImage: "figure.hiking")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.72, green: 0.41, blue: 0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }
}

struct HikingMetricView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    HikingView()
}
