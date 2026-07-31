//
//  AllEventList.swift
//  Fielmedina
//
//  Created by Aslan on 1/13/26.
//
//  UI only. State and logic live in `AllEventsModel` — see `AllLocationsModel`
//  for the reasoning behind this pattern.
//

import SwiftUI

struct AllEventsListView: View {
    /// Held with @State so it is created once and survives body re-evaluation,
    /// the SwiftUI equivalent of an Android ViewModel.
    @State private var model = AllEventsModel()

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
                            title: "Regions",
                            options: model.cityOptions,
                            selectedId: model.selectedCityId
                        ) { model.selectedCityId = $0 }

                        Spacer()

                        InlineFilterChip(
                            icon: "slider.horizontal.3",
                            title: "Filter",
                            options: model.categoryOptions,
                            selectedId: model.selectedCategoryId
                        ) { model.selectedCategoryId = $0 }
                    }
                    .padding(.horizontal, 16)

                    if model.isLoading {
                        VStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { _ in
                                EventItemSkeleton()
                            }
                        }
                        .padding(.horizontal, 16)
                    } else if let error = model.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                            Button("Try Again") {
                                Task { await model.loadData() }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal)
                    } else if model.displayedEvents.isEmpty {
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
                            ForEach(model.displayedEvents) { event in
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
                                .task(id: model.events.count) {
                                    // Near the bottom — pull the next page. Keyed on the RAW
                                    // loaded count, not the filtered list: a page may add no
                                    // rows matching the active filter, and keying on the
                                    // filtered list would leave the trigger stuck while more
                                    // pages still exist.
                                    if model.isNearEnd(event) {
                                        model.loadNextPage()
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
                await model.refreshFromNetwork()
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
            await model.loadData()
        }
    }
}

#Preview {
    AllEventsListView()
}
