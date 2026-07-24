//
//  GlobalSearchOverlay.swift
//  Fielmedina
//
//  A single search across locations, events and merchants, shown as a dimmed
//  overlay over Home. Results are a flat list tagged with a type badge; tapping
//  one opens its detail screen.
//

import SwiftUI
import Combine

enum GlobalSearchResult: Identifiable, Hashable {
    case location(Location)
    case event(Event)
    case merchant(Merchant)

    var id: String {
        switch self {
        case .location(let l): return "loc_\(l.id)"
        case .event(let e): return "evt_\(e.id)"
        case .merchant(let m): return "mer_\(m.id)"
        }
    }

    var name: String {
        switch self {
        case .location(let l): return l.displayName
        case .event(let e): return e.displayName
        case .merchant(let m): return m.displayName
        }
    }

    var typeLabel: LocalizedStringKey {
        switch self {
        case .location: return "Location"
        case .event: return "Event"
        case .merchant: return "Pick"
        }
    }

    var iconName: String {
        switch self {
        case .location: return "mappin.circle.fill"
        case .event: return "calendar"
        case .merchant: return "bag.fill"
        }
    }
}

@MainActor
final class GlobalSearchModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var isLoading = false

    private var locations: [Location] = []
    private var events: [Event] = []
    private var merchants: [Merchant] = []
    private var loaded = false

    /// Loads all three datasets once. These hit the Apollo cache the prefetcher
    /// warmed, so it's fast and works offline.
    func loadIfNeeded() async {
        guard !loaded else { return }
        isLoading = true
        async let locs = try? LocationService.shared.fetchLocations(limit: 500)
        async let evts = try? EventService.shared.fetchEvents(limit: 200)
        async let mers = try? MerchantService.shared.fetchMerchants(limit: 200)
        let (l, e, m) = await (locs, evts, mers)
        locations = l ?? []
        events = e ?? []
        merchants = m ?? []
        loaded = true
        isLoading = false
    }

    var results: [GlobalSearchResult] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        var out: [GlobalSearchResult] = []
        out += locations.filter { $0.displayName.localizedCaseInsensitiveContains(q) }.map { .location($0) }
        out += events.filter { $0.displayName.localizedCaseInsensitiveContains(q) }.map { .event($0) }
        out += merchants.filter { $0.displayName.localizedCaseInsensitiveContains(q) }.map { .merchant($0) }
        return out
    }
}

struct GlobalSearchOverlay: View {
    @Binding var isPresented: Bool
    var onSelect: (GlobalSearchResult) -> Void

    @StateObject private var model = GlobalSearchModel()
    @FocusState private var focused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 12) {
                searchBar

                if !model.query.trimmingCharacters(in: .whitespaces).isEmpty {
                    resultsCard
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .task {
            await model.loadIfNeeded()
            focused = true
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search places, events, picks", text: $model.query)
                    .focused($focused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                if !model.query.isEmpty {
                    Button {
                        model.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedCornerShapeCompat()
            )

            Button("Cancel") { dismiss() }
                .font(.system(size: 16, weight: .semibold))
        }
    }

    private var resultsCard: some View {
        let results = model.results
        return VStack(spacing: 0) {
            if results.isEmpty {
                HStack {
                    Text(model.isLoading ? "Loading…" : "No results")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    Spacer()
                }
                .padding(16)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                            Button {
                                onSelect(result)
                                isPresented = false
                            } label: {
                                resultRow(result)
                            }
                            .buttonStyle(.plain)

                            if index < results.count - 1 {
                                Divider().padding(.leading, 52)
                            }
                        }
                    }
                }
                .frame(maxHeight: 420)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }

    private func resultRow(_ result: GlobalSearchResult) -> some View {
        HStack(spacing: 12) {
            Image(systemName: result.iconName)
                .font(.system(size: 18))
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            Text(result.name)
                .font(.system(size: 16))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            Text(result.typeLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(Color(.secondarySystemBackground))
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func dismiss() {
        focused = false
        isPresented = false
    }
}

/// Small helper so the search field background matches the app's list search field.
private struct RoundedCornerShapeCompat: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(.systemGray4), lineWidth: 1)
            )
    }
}
