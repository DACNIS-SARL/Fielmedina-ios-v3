//
//  PublicTransports.swift
//  Fielmedina
//
//  Created by Aslan on 1/21/26.
//

import SwiftUI

enum TransportMode: String, CaseIterable, Identifiable {
    case bus
    case train
    case metro

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bus:
            return String(localized: "transport_bus")
        case .train:
            return String(localized: "transport_train")
        case .metro:
            return String(localized: "transport_metro")
        }
    }

    var iconName: String {
        switch self {
        case .bus:
            return "bus"
        case .train:
            return "train.side.rear.car"
        case .metro:
            return "train.side.front.car"
        }
    }
}

struct PublicTransports: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: TransportMode = .bus
    @State private var transports: [PublicTransport] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                
                VStack(spacing: 24) {
                    infoCard
                        .padding(.top, -60)
                    
                    VStack(spacing: 24) {
                        modePicker
                        contentSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .padding(.top, -20)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Public transport")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsButton()
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            await loadTransports()
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .top) {
            Image("public-transports")
                .resizable()
                .scaledToFill()
                .frame(height: 360)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.4), .clear, .black.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("A tip")
                .font(.title3)
                .bold()
                .foregroundStyle(.white)
            
            Text("Take public transport for an easy and budget-friendly trip to the Medina.\nA great choice for local vibes and saving money.")
                .font(.system(size: 16))
                .lineSpacing(4)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(TransportMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 16, weight: .semibold))
                        Text(mode.title)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background {
                        if selectedMode == mode {
                            Capsule()
                                .fill(.white)
                                .shadow(color: .black.opacity(0.1), radius: 4)
                        }
                    }
                    .foregroundStyle(.black)
                }
            }
        }
        .padding(4)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var contentSection: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView("Loading routes...")
                        .padding(.top, 40)
                }
                .frame(maxWidth: .infinity)
                .transition(.opacity)
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
                        Task { await loadTransports() }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
                .transition(.opacity)
            } else if filteredTransports.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bus.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary.opacity(0.5))
                    
                    Text("No trips available")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    Text("Check back later for updated schedules.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
                .padding(.bottom, 20)
                .transition(.opacity)
            } else {
                VStack(spacing: 32) {
                    ForEach(groupedTransports, id: \.cityName) { cityGroup in
                        TransportCitySection(city: cityGroup.cityName, routePairs: groupRoutesIntoPairs(cityGroup.routes))
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(minHeight: 300) // Stabilize layout
        .animation(.smooth(duration: 0.3), value: selectedMode)
        .animation(.smooth(duration: 0.3), value: isLoading)
    }

    private var groupedTransports: [TransportCityGroup] {
        let grouped = Dictionary(grouping: filteredTransports) { $0.displayCity ?? "" }
        return grouped.keys.sorted().map { key in
            TransportCityGroup(cityName: key, routes: grouped[key] ?? [])
        }
    }

    private var filteredTransports: [PublicTransport] {
        transports.filter { transport in
            transport.publicTransportType.displayName.lowercased() == selectedMode.title.lowercased()
        }
    }

    private func loadTransports() async {
        isLoading = true
        errorMessage = nil
        do {
            transports = try await PublicTransportService.shared.fetchTransports(limit: 80)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func groupRoutesIntoPairs(_ routes: [PublicTransport]) -> [TransportPair] {
        var pairs: [TransportPair] = []
        var processedIds = Set<String>()

        for route in routes {
            if processedIds.contains(route.id) { continue }

            // Look for a reverse route
            let reverse = routes.first { other in
                !processedIds.contains(other.id) &&
                other.id != route.id &&
                other.fromRegionEn == route.toRegionEn &&
                other.toRegionEn == route.fromRegionEn
            }

            if let reverseRoute = reverse {
                pairs.append(TransportPair(forward: route, backward: reverseRoute))
                processedIds.insert(route.id)
                processedIds.insert(reverseRoute.id)
            } else {
                pairs.append(TransportPair(forward: route, backward: nil))
                processedIds.insert(route.id)
            }
        }
        return pairs
    }
}

struct TransportPair: Identifiable {
    var id: String { forward.id }
    let forward: PublicTransport
    let backward: PublicTransport?
}

struct TransportCityGroup: Identifiable {
    let cityName: String
    let routes: [PublicTransport]

    var id: String { cityName }
}

struct TransportCitySection: View {
    let city: String
    let routePairs: [TransportPair]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(city)
                .font(.title2)
                .bold()

            ForEach(routePairs) { pair in
                TransportRouteCard(pair: pair)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TransportRouteCard: View {
    let pair: TransportPair

    private func getName(from: String, to: String) -> (String, String) {
        return (from, to)
    }

    private func formatTime(_ time: String) -> String {
        // If time is HH:mm:ss, take first 5 chars
        if time.count >= 5 {
            return String(time.prefix(5))
        }
        return time
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Forward Route
            VStack(alignment: .leading, spacing: 12) {
                routeHeader(from: pair.forward.fromRegionFr.isEmpty ? pair.forward.fromRegionEn : pair.forward.fromRegionFr,
                           to: pair.forward.toRegionFr.isEmpty ? pair.forward.toRegionEn : pair.forward.toRegionFr)
                
                timeGrid(times: pair.forward.displayTimes)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Backward Route
            if let backward = pair.backward {
                VStack(alignment: .leading, spacing: 12) {
                    routeHeader(from: backward.fromRegionFr.isEmpty ? backward.fromRegionEn : backward.fromRegionFr,
                               to: backward.toRegionFr.isEmpty ? backward.toRegionEn : backward.toRegionFr)
                    
                    timeGrid(times: backward.displayTimes)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func routeHeader(from: String, to: String) -> some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(from)
                Text(to)
            }
            .font(.system(size: 15, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 14, weight: .semibold))
        }
    }
    
    @ViewBuilder
    private func timeGrid(times: [String]) -> some View {
        let columns = [GridItem(.fixed(65)), GridItem(.fixed(65))]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(times, id: \.self) { time in
                HStack(spacing: 4) {
                    Image(systemName: "clock.badge")
                        .font(.system(size: 10))
                    Text(formatTime(time))
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PublicTransports()
    }
}
