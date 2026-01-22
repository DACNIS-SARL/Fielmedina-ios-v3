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
            return "Bus"
        case .train:
            return "Train"
        case .metro:
            return "Metro"
        }
    }

    var iconName: String {
        switch self {
        case .bus:
            return "bus.fill"
        case .train:
            return "train.side.front.car"
        case .metro:
            return "tram.fill"
        }
    }
}

struct PublicTransports: View {
    @State private var selectedMode: TransportMode = .bus
    @State private var transports: [PublicTransport] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroSection
                    infoCard
                    modePicker
                    contentSection
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsButton()
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadTransports()
            }
        }
    }

    private var heroSection: some View {
        ZStack {
            Image("public-transports")
                .resizable()
                .scaledToFill()
                .frame(height: 260)
                .clipped()

            VStack {
                Text("Public transport")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Info")
                .font(.headline)
            Text("Take public transport for an easy and budget-friendly trip to the Medina. A great choice for local vibes and saving money.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
    }

    private var modePicker: some View {
        Picker("Transport mode", selection: $selectedMode) {
            ForEach(TransportMode.allCases) { mode in
                Label(mode.title, systemImage: mode.iconName)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .onChange(of: selectedMode) { _, _ in
            Task { await loadTransports() }
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        if isLoading {
            ProgressView("Loading routes...")
                .padding(.top, 24)
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
            .padding(.top, 24)
        } else if transports.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "bus")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("No routes available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
        } else {
            VStack(spacing: 16) {
                ForEach(groupedTransports, id: \.cityName) { cityGroup in
                    TransportCitySection(city: cityGroup.cityName, routes: cityGroup.routes)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
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
}

struct TransportCityGroup: Identifiable {
    let cityName: String
    let routes: [PublicTransport]

    var id: String { cityName }
}

struct TransportCitySection: View {
    let city: String
    let routes: [PublicTransport]

    private let timeColumns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(city)
                .font(.title3)
                .bold()

            ForEach(routes) { route in
                TransportRouteCard(route: route, timeColumns: timeColumns)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}

struct TransportRouteCard: View {
    let route: PublicTransport
    let timeColumns: [GridItem]

    private var fromName: String {
        route.fromRegionFr.isEmpty ? route.fromRegionEn : route.fromRegionFr
    }

    private var toName: String {
        route.toRegionFr.isEmpty ? route.toRegionEn : route.toRegionFr
    }

    private var times: [String] {
        route.displayTimes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(fromName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(toName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 18, weight: .semibold))
            }

            LazyVGrid(columns: timeColumns, alignment: .leading, spacing: 6) {
                ForEach(times, id: \.self) { time in
                    Label(time, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        PublicTransports()
    }
}
