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
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                HeroBanner(
                    imageName: "public-transports",
                    showText: false
                )
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 24) {
                    infoCard
                        .padding(.top, -80)
                    
                    VStack(spacing: 24) {
                        modePicker
                        contentSection
                    }
                    .padding(26)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 100)
            }
            .frame(maxWidth: .infinity)
        }
        .coordinateSpace(name: "scroll")
        .ignoresSafeArea(edges: .top)
        .ignoresSafeArea(edges: .horizontal)
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
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("A tip")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Take public transport for an easy and budget-friendly trip to the Medina.")
                    .font(.system(size: 16))
                Text("A great choice for local vibes and saving money.")
                    .font(.system(size: 16))
            }
            .foregroundStyle(.white.opacity(0.95))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.2, green: 0.2, blue: 0.2))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
    }
    
    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(TransportMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 14, weight: .semibold))
                        Text(mode.title)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .background {
                        if selectedMode == mode {
                            Capsule()
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 4)
                        }
                    }
                    .foregroundStyle(selectedMode == mode ? .primary : .secondary)
                }
            }
        }
        .padding(4)
        .background(Color(.secondarySystemBackground))
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
        let previousTransports = transports
        do {
            transports = try await PublicTransportService.shared.fetchTransports(limit: 400)
        } catch {
            transports = previousTransports
            if previousTransports.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
    
    private func groupRoutesIntoPairs(_ routes: [PublicTransport]) -> [TransportPair] {
        var pairs: [TransportPair] = []
        var processedIds = Set<String>()
        
        for route in routes {
            if processedIds.contains(route.id) { continue }
            
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
    @Environment(\.horizontalSizeClass) var sizeClass
    
    private func formatTime(_ time: String) -> String {
        if time.count >= 5 {
            return String(time.prefix(5))
        }
        return time
    }
    
    var body: some View {
        ViewThatFits {
            horizontalLayout
            verticalLayout
        }
        .padding(.vertical, 8)
    }
    
    private var horizontalLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            routeSection(
                from: pair.forward.fromRegionFr.isEmpty ? pair.forward.fromRegionEn : pair.forward.fromRegionFr,
                to: pair.forward.toRegionFr.isEmpty ? pair.forward.toRegionEn : pair.forward.toRegionFr,
                times: pair.forward.displayTimes,
                busNumber: pair.forward.busNumber
            )
            
            if let backward = pair.backward {
                routeSection(
                    from: backward.fromRegionFr.isEmpty ? backward.fromRegionEn : backward.fromRegionFr,
                    to: backward.toRegionFr.isEmpty ? backward.toRegionEn : backward.toRegionFr,
                    times: backward.displayTimes,
                    busNumber: backward.busNumber
                )
            }
        }
    }
    
    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: 16) {
            routeSection(
                from: pair.forward.fromRegionFr.isEmpty ? pair.forward.fromRegionEn : pair.forward.fromRegionFr,
                to: pair.forward.toRegionFr.isEmpty ? pair.forward.toRegionEn : pair.forward.toRegionFr,
                times: pair.forward.displayTimes,
                busNumber: pair.forward.busNumber
            )
            
            if let backward = pair.backward {
                routeSection(
                    from: backward.fromRegionFr.isEmpty ? backward.fromRegionEn : backward.fromRegionFr,
                    to: backward.toRegionFr.isEmpty ? backward.toRegionEn : backward.toRegionFr,
                    times: backward.displayTimes,
                    busNumber: backward.busNumber
                )
            }
        }
    }
    
    @ViewBuilder
    private func routeSection(from: String, to: String, times: [String], busNumber: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(from)
                    Text(to)
                }
                .font(.system(size: 15, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                
                Image(systemName: "arrow.turn.down.left")
                    .font(.system(size: 14, weight: .semibold))
                    .rotationEffect(.degrees(-20))
                
                Spacer(minLength: 0)
                
                Text("Bus \(busNumber)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }
            
            timeGrid(times: times)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func timeGrid(times: [String]) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(times, id: \.self) { time in
                HStack(spacing: 4) {
                    Image(systemName: "clock.badge")
                        .font(.system(size: 13))
                    Text(formatTime(time))
                        .font(.system(size: 14, weight: .medium))
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
