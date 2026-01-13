import SwiftUI

struct AllEventsListView: View {
    @State private var selectedCategory: String = "All Events"
    @State private var showFilterSheet = false
    
    let categories = [
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
    
    let events: [Event] = [
        Event(
            title: "7th International Festival of Circus and Street Arts",
            date: "Thu, Feb 13, 8:30PM",
            price: "145 TND",
            imageName: "event-e",
            category: "Spectacle / Show"
        ),
        Event(
            title: "Tabarka Jazz Festival 2026",
            date: "Fri, Mar 20, 7:00PM",
            price: "50 TND",
            imageName: "event-e",
            category: "Live Music & Concerts"
        ),
        Event(
            title: "Traditional Pottery Workshop",
            date: "Sat, Apr 15, 10:00AM",
            price: "Free",
            imageName: "event-e",
            category: "Workshop / Class"
        ),
        Event(
            title: "Medina Heritage Walking Tour",
            date: "Sun, Apr 16, 9:00AM",
            price: "25 TND",
            imageName: "event-e",
            category: "Guided Tour / Walk"
        ),
        Event(
            title: "Carthage History Re-enactment",
            date: "Mon, May 1, 3:00PM",
            price: "30 TND",
            imageName: "event-e",
            category: "Historical Re-enactment"
        )
    ]
    
    
    var filteredEvents: [Event] {
        if selectedCategory == "All Events" {
            return events
        } else {
            return events.filter { $0.category == selectedCategory }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if filteredEvents.isEmpty {
                    // Empty state
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
                } else {
                    
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // CHANGE THIS: events -> filteredEvents
                            ForEach(filteredEvents) { event in
                                Item(event: event)
                                    .onTapGesture {
                                        FirebaseUtils.trackButtonTap(
                                            buttonName: "event_item",
                                            screenName: "AllEvents"
                                        )
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle(selectedCategory)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                CategoryFilterView(
                    categories: categories,
                    selectedCategory: $selectedCategory,
                    isPresented: $showFilterSheet
                )
            }
        }
    }
}

// MARK: - Category Filter View

struct CategoryFilterView: View {
    let categories: [String]
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
