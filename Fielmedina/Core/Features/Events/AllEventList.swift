//
//  AllEventList.swift
//  Fielmedina
//
//  Created by Aslan on 1/13/26.
//

import SwiftUI

struct AllEventsListView: View {
    @State private var selectedCategory: String = "All Events"
    @State private var showFilterSheet = false
    @State private var categories: [String] = ["All Events"] // Dynamic categories
    @State private var isLoadingCategories = false
    
    let events = EventsData.sampleEvents
    
    var filteredEvents: [Event] {
        if selectedCategory == "All Events" {
            return events
        } else {
            return events.filter { $0.category?.displayName == selectedCategory }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        CarouselListEvent(
                            title: "Upcoming events",
                            subtitle: "Top events",
                            events: events,
                            showShowAllButton: false
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

                        if filteredEvents.isEmpty {
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
                    categories: $categories,
                    selectedCategory: $selectedCategory,
                    isPresented: $showFilterSheet
                )
            }
            .task {
                await loadCategories()
            }
        }
    }
    
    private func loadCategories() async {
        isLoadingCategories = true
        
        do {
            print("🔄 Fetching event categories from API...")
            let fetchedCategories = try await EventCategoryService.shared.fetchEventCategories()
            print("✅ Fetched \(fetchedCategories.count) categories")
            for cat in fetchedCategories {
                print("   - \(cat.id): \(cat.nameEn) / \(cat.nameFr ?? "nil")")
            }
            let categoryNames = fetchedCategories.map { $0.displayName }
            categories = ["All Events"] + categoryNames
            print("📋 Final categories: \(categories)")
        } catch {
            print("❌ Error loading categories: \(error)")
            // Keep default categories on error
            categories = [
                "All Events",
                "Spectacle / Show",
                "Seasonal Event",
                "Workshop / Class",
                "Guided Tour / Walk",
                "Historical Re-enactment",
                "Market / Fair",
                "Food & Drink Festival",
                "Live Music & Concerts",
                "Exhibition / Art Show",
                "Cultural Festival"
            ]
        }
        
        isLoadingCategories = false
    }
}


struct CategoryFilterView: View {
    @Binding var categories: [String]
    @Binding var selectedCategory: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
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
                            
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color(red: 0.702, green: 0.435, blue: 0.227))
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .padding(.vertical, 4)
                    }
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

