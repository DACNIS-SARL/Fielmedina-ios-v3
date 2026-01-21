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
    @State private var showFilterSheet = false
    @State private var categories: [String] = [String(localized: "All Events")]
    @State private var isLoadingEvents = true
    @State private var isLoadingCategories = false
    @State private var errorMessage: String?
    
    var filteredEvents: [Event] {
        if selectedCategory == String(localized: "All Events") {
            return events
        } else {
            return events.filter { $0.category?.displayName == selectedCategory }
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    CarouselListEvent(
                        title: "Upcoming events",
                        subtitle: "Top events",
                        showShowAllButton: false,
                        isBoostedOnly: true
                    )
                    .padding(.bottom, 8)

                    HStack {
                        Text("ALL EVENTS")
                            .font(.caption).bold()
                            .foregroundStyle(.secondary)

                        Spacer()
                        
                        Button {
                            showFilterSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Filter")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)

                    if isLoadingEvents {
                        VStack {
                            ProgressView("Loading events...")
                                .padding(.vertical, 40)
                        }
                        .frame(maxWidth: .infinity)
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
                        VStack(spacing: 12) {
                            ForEach(filteredEvents) { event in
                                EventItem(event: event)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color(.secondarySystemBackground))
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .onTapGesture {
                                        FirebaseUtils.trackButtonTap(
                                            buttonName: "event_item",
                                            screenName: "AllEvents"
                                        )
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
                .padding(.top, 12)
            }
        }
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsButton()
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            CategoryFilterView(
                availableCategories: $categories,
                currentSelection: $selectedCategory,
                isPresented: $showFilterSheet
            )
        }
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        isLoadingEvents = true
        isLoadingCategories = true
        errorMessage = nil
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadEvents() }
            group.addTask { await loadCategories() }
        }
        
        isLoadingEvents = false
        isLoadingCategories = false
    }
    
    private func loadEvents() async {
        do {
            self.events = try await EventService.shared.fetchEvents(limit: 50)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadCategories() async {
        do {
            let fetchedCategories = try await EventCategoryService.shared.fetchEventCategories()
            let categoryNames = fetchedCategories.map { $0.displayName }
            categories = [String(localized: "All Events")] + categoryNames
        } catch {
            categories = [String(localized: "All Events")]
        }
    }
}


struct CategoryFilterView: View {
    @Binding var availableCategories: [String]
    @Binding var currentSelection: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(availableCategories, id: \.self) { (category: String) in
                    Button {
                        currentSelection = category
                        isPresented = false
                        
                        FirebaseUtils.trackButtonTap(
                            buttonName: "filter_\(category)",
                            screenName: "AllEvents"
                        )
                    } label: {
                        HStack {
                            Text(category)
                                .font(.system(size: 16))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if currentSelection == category {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.primary)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Filter by Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    AllEventsListView()
}

