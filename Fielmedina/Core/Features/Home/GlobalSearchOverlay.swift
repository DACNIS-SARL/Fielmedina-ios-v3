//
//  GlobalSearchOverlay.swift
//  Fielmedina
//
//  A single search across locations, events and merchants, shown as a dimmed
//  overlay over Home. Results are a flat list tagged with a type badge and a
//  thumbnail; tapping one opens its detail screen.
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

    var imageURL: String? {
        switch self {
        case .location(let l): return l.imageURL
        case .event(let e): return e.imageURL
        case .merchant(let m): return m.imageURL
        }
    }

    var typeLabel: LocalizedStringKey {
        switch self {
        case .location: return "Location"
        case .event: return "Event"
        case .merchant: return "Pick"
        }
    }

    var fallbackIcon: String {
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
    var namespace: Namespace.ID
    var fieldID: String
    var onSelect: (GlobalSearchResult) -> Void

    @StateObject private var model = GlobalSearchModel()
    @FocusState private var focused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }
                .transition(.opacity)

            VStack(spacing: 0) {
                header

                if !model.query.trimmingCharacters(in: .whitespaces).isEmpty {
                    resultsCard
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .transition(.opacity)
                }

                Spacer(minLength: 0)
            }
        }
        .task {
            await model.loadIfNeeded()
            focused = true
        }
    }

    /// The glassy search field floats over the dimmed content (no solid bar).
    /// The pill shares a matched-geometry id with Home's in-place field, so
    /// opening the overlay looks like that field lifting up to the top.
    private var header: some View {
        HStack(spacing: 12) {
            searchField
                .glassSearchField()
                .matchedGeometryEffect(id: fieldID, in: namespace)

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var searchField: some View {
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
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var resultsCard: some View {
        let results = model.results
        return VStack(spacing: 0) {
            if results.isEmpty {
                HStack {
                    Text(model.isLoading ? "Loading…" : "No results found")
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
                                focused = false
                                onSelect(result)
                                isPresented = false
                            } label: {
                                resultRow(result)
                            }
                            .buttonStyle(.plain)

                            if index < results.count - 1 {
                                Divider().padding(.leading, 68)
                            }
                        }
                    }
                }
                .frame(maxHeight: 440)
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
            FielmedinaImage(url: result.imageURL, contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color(.systemGray5), lineWidth: 1)
                )

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
                .background(Capsule().fill(Color(.secondarySystemBackground)))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func dismiss() {
        focused = false
        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) { isPresented = false }
    }
}

extension View {
    /// Rounded, glassy search-field background. Uses the iOS 26 Liquid Glass
    /// effect where available and falls back to an ultra-thin material capsule.
    @ViewBuilder
    func glassSearchField() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            self
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
                )
        }
    }
}
