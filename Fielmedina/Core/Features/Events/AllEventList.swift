//
//  AllEventList.swift
//  Fielmedina
//
//  Created by Aslan on 1/13/26.
//

import SwiftUI

struct AllEventsListView: View {
    @State private var events: [Event] = []
    @State private var selectedCategory: String = String(localized: "All Events")
    @State private var categories: [String] = [String(localized: "All Events")]
    @State private var isLoadingEvents = true
    @State private var isRefreshing = false
    @State private var isLoadingCategories = false
    @State private var errorMessage: String?
    @State private var isConnected = NetworkMonitor.shared.isConnected
    @State private var currentLimit: Int32 = 50
    @State private var hasMoreData = true
    @State private var selectedCityId: String? = nil

    /// Distinct cities present in the loaded events, so the filter only offers
    /// cities that actually have content. Client-side, so it works offline.
    private var availableCities: [EventCity] {
        var seen = Set<String>()
        var result: [EventCity] = []
        for event in events {
            if let city = event.city, !seen.contains(city.id) {
                seen.insert(city.id)
                result.append(city)
            }
        }
        return result.sorted { $0.displayName < $1.displayName }
    }

    private var cityOptions: [FilterMenuOption] {
        [FilterMenuOption(id: nil, label: String(localized: "All Cities"))]
            + availableCities.map { FilterMenuOption(id: $0.id, label: $0.displayName) }
    }

    private var categoryOptions: [FilterMenuOption] {
        categories.map { name in
            FilterMenuOption(id: name == String(localized: "All Events") ? nil : name, label: name)
        }
    }

    var filteredEvents: [Event] {
        var result = events
        if let cityId = selectedCityId {
            result = result.filter { $0.city?.id == cityId }
        }
        if selectedCategory != String(localized: "All Events") {
            result = result.filter { $0.category?.displayName == selectedCategory }
        }
        return result
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    CarouselListEvent(
                        title: "Upcoming events",
                        subtitle: "Top events",
                        showShowAllButton: false,
                        isBoostedOnly: true,
                        bottomPadding: 8
                    )
                    
                    AdsCarousel()

                    HStack(spacing: 8) {
                        InlineFilterChip(
                            icon: "mappin.and.ellipse",
                            title: "Cities",
                            options: cityOptions,
                            selectedId: selectedCityId
                        ) { selectedCityId = $0 }

                        Spacer()

                        InlineFilterChip(
                            icon: "slider.horizontal.3",
                            title: "Filter",
                            options: categoryOptions,
                            selectedId: selectedCategory == String(localized: "All Events") ? nil : selectedCategory
                        ) { selectedCategory = $0 ?? String(localized: "All Events") }
                    }
                    .padding(.horizontal, 16)

                    if isLoadingEvents {
                        VStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { _ in
                                EventItemSkeleton()
                            }
                        }
                        .padding(.horizontal, 16)
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                            Button("Try Again") {
                                Task { await loadData() }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal)
                    } else if filteredEvents.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)

                            Text("No Events Found")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("There are no events in this category yet.\nCheck back soon!")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredEvents) { event in
                                NavigationLink {
                                    EventDetailView(event: event)
                                } label: {
                                    EventItem(event: event)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color(.secondarySystemBackground))
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    // Detect when user hits the bottom of the vertical list.
                                    // Skip while searching — search filters the already-loaded set.
                                    if event.id == filteredEvents.last?.id && !isLoadingEvents && !isRefreshing && hasMoreData {
                                        currentLimit += 50
                                        Task { await refreshFromNetwork() }
                                    }
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    FirebaseUtils.trackButtonTap(
                                        buttonName: "event_item",
                                        screenName: "AllEvents"
                                    )
                                })
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
                .padding(.top, 12)
            }
            .refreshable {
                await refreshFromNetwork()
            }
        }
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsButton()
            }
        }
        .task {
            await loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .networkStatusChanged)) { notification in
            guard let isConnected = notification.userInfo?["isConnected"] as? Bool else { return }
            self.isConnected = isConnected
        }
        .onChange(of: isConnected) { _, newValue in
            guard newValue else { return }
            Task { await refreshFromNetwork() }
        }
    }
    
    private func loadData(forceRefresh: Bool = false) async {
        if events.isEmpty {
            isLoadingEvents = true
        }
        isLoadingCategories = true
        errorMessage = nil
        
        let previousEvents = events
        let previousCategories = categories
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadEvents(forceRefresh: forceRefresh) }
            group.addTask { await loadCategories() }
        }
        
        if events.isEmpty && !previousEvents.isEmpty {
            events = previousEvents
        }
        
        if categories.count == 1 && previousCategories.count > 1 {
            categories = previousCategories
        }
        
        // Final offline fallback: if categories are still only "All Events" but we have events,
        // rebuild categories from events to enable offline filtering.
        if categories.count == 1, !events.isEmpty {
            let derived = Array(Set(events.compactMap { $0.category?.displayName })).sorted()
            if !derived.isEmpty {
                categories = [String(localized: "All Events")] + derived
            }
        }
        
        isLoadingEvents = false
        isLoadingCategories = false
    }
    
    private func loadEvents(forceRefresh: Bool = false) async {
        do {
            if forceRefresh && events.isEmpty {
                 currentLimit = 50
                 hasMoreData = true
            }
            let fetched = try await EventService.shared.fetchEvents(limit: currentLimit, forceRefresh: forceRefresh)
            if fetched.count < currentLimit {
                hasMoreData = false
            } else {
                hasMoreData = true
            }
            self.events = fetched
        } catch {
            if events.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func loadCategories() async {
        do {
            let fetchedCategories = try await EventCategoryService.shared.fetchEventCategories()
            let categoryNames = Array(Set(fetchedCategories.map { $0.displayName })).sorted()
            categories = [String(localized: "All Events")] + categoryNames
        } catch {
            // Offline or fetch failed — derive categories from already-loaded events
            let derived = Array(Set(events.compactMap { $0.category?.displayName })).sorted()
            if derived.isEmpty {
                categories = [String(localized: "All Events")]
            } else {
                categories = [String(localized: "All Events")] + derived
            }
        }
    }

    private func refreshFromNetwork() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        await loadData(forceRefresh: true)
    }
}


#Preview {
    AllEventsListView()
}
