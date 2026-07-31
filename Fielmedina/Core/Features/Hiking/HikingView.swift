//
//  HikingView.swift
//  Fielmedina
//
//  Created by Aslan on 1/8/26.
//

import SwiftUI
import CoreLocation
import MapboxDirections
import MapboxNavigationCore

struct HikingView: View {
    /// Held with @State so it is created once and survives body re-evaluation,
    /// the SwiftUI equivalent of an Android ViewModel. Route metrics live in here,
    /// so returning to this screen no longer recomputes every trail's route.
    @State private var model = HikingListModel()
    @State private var locationManager = LocationManager()
    @State private var selectedHiking: Hiking?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if model.isLoading {
                        HikingSkeletonList()
                    } else if let errorMessage = model.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundStyle(.red)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task { await model.loadTrails() }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if model.trails.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "figure.hiking")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)

                            Text(String(localized: "No Hiking Routes Yet"))
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text(String(localized: "There are no hiking routes in this city yet.\nCheck back soon!"))
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 20) {
                            ForEach(model.trails.indices, id: \.self) { index in
                                let trail = model.trails[index]
                                HikingCardView(
                                    hiking: trail,
                                    metrics: model.metrics[trail.id],
                                    onStart: {
                                        selectedHiking = trail
                                    }
                                )

                                if index < model.trails.count - 1 {
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
                await model.loadTrails()
            }
            // The View owns CoreLocation permission/lifecycle and feeds the coordinate
            // in; the model buckets it so trails are only re-sorted and re-routed when
            // the user has actually moved, not on every GPS tick.
            .onChange(of: locationManager.userLocation?.latitude) { _, _ in
                model.updateUserLocation(locationManager.userLocation)
            }
            .onChange(of: locationManager.userLocation?.longitude) { _, _ in
                model.updateUserLocation(locationManager.userLocation)
            }
            .fullScreenCover(item: $selectedHiking) { hiking in
                HikingNavigator(
                    hikingRoute: hiking,
                    initialUserLocation: locationManager.userLocation
                )
                .ignoresSafeArea()
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

}

struct HikingSkeletonList: View {
    var body: some View {
        VStack(spacing: 20) {
            ForEach(0..<3, id: \.self) { _ in
                HikingSkeletonCard()
            }
        }
        .redacted(reason: .placeholder)
    }
}

struct HikingSkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemGray5))
                .frame(height: 220)

            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(.systemGray5))
                        .frame(width: 64, height: 48)
                }
            }

            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(height: 22)

            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(height: 16)

            HStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 16)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 16)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 16)
            }

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray5))
                .frame(height: 46)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }
}

struct HikingMetrics {
    let distance: Double
    let duration: TimeInterval
}

struct HikingCardView: View {
    let hiking: Hiking
    let metrics: HikingMetrics?
    let onStart: () -> Void

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
        if duration <= 0 { return "--" }
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

//                Circle()
//                    .fill(Color.pink)
//                    .frame(width: 36, height: 36)
//                    .overlay(
//                        Image(systemName: "mappin.and.ellipse")
//                            .font(.system(size: 16, weight: .semibold))
//                            .foregroundColor(.white)
//                    )
//                    .padding(12)
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
                HTMLTextView(
                    html: description,
                    textStyle: .subheadline,
                    textColor: .secondary,
                    lineLimit: 3
                )
            }

            HStack(spacing: 24) {
                HikingMetricView(title: String(localized: "Distance"), value: distanceText)
                HikingMetricView(title: String(localized: "Duration"), value: durationText)
                HikingMetricView(title: String(localized: "Waypoints"), value: "\(hiking.orderedLocations.count)")
            }
            .padding(.top, 8)

            Button {
                FirebaseUtils.trackButtonTap(buttonName: "start_hiking_\(hiking.displayName)", screenName: "HikingView")
                onStart()
            } label: {
                Label(String(localized: "Start Hiking"), systemImage: "figure.hiking")
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
