//
//  AllTipsListView.swift
//  Fielmedina
//
//  Created by Aslan on 3/18/26.
//

import SwiftUI

struct AllTipsListView: View {
    @State private var allTips: [Tip] = []           // All fetched tips
    @State private var displayedCount: Int = 10       // Client-side pagination
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isConnected = NetworkMonitor.shared.isConnected
    @Environment(\.scenePhase) private var scenePhase
    
    private let pageSize = 10
    
    /// Tips currently visible in the list
    private var visibleTips: ArraySlice<Tip> {
        allTips.prefix(displayedCount)
    }
    
    /// Whether there are more tips to reveal locally
    private var hasMoreToShow: Bool {
        displayedCount < allTips.count
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
                        isBoostedOnly: true,
                        bottomPadding: 8
                    )
                    
                    AdsCarousel()
                    
                    HStack {
                        Text("ALL TIPS")
                            .font(.caption).bold()
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    
                    if isLoading {
                        VStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { _ in
                                TipItemSkeleton()
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
                                Task { await loadTips() }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal)
                    } else if allTips.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "lightbulb.slash")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            
                            Text("No Tips Yet")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("There are no tips available yet.\nCheck back soon!")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(Array(visibleTips)) { tip in
                                TipItem(tip: tip)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color(.secondarySystemBackground))
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .onAppear {
                                        // Load more when reaching the last 3 visible items
                                        if tip.id == Array(visibleTips).suffix(3).first?.id && hasMoreToShow {
                                            withAnimation(.smooth) {
                                                displayedCount = min(displayedCount + pageSize, allTips.count)
                                            }
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
                .padding(.top, 12)
            }
            .refreshable {
                await refreshTips()
            }
        }
        .navigationTitle("Tips")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsButton()
            }
        }
        .task {
            FirebaseUtils.trackScreenView(screenName: "all_tips", screenClass: "AllTipsListView")
            await loadTips()
        }
        .onReceive(NotificationCenter.default.publisher(for: .networkStatusChanged)) { notification in
            guard let isConnected = notification.userInfo?["isConnected"] as? Bool else { return }
            self.isConnected = isConnected
        }
        .onChange(of: isConnected) { _, newValue in
            guard newValue else { return }
            Task { await refreshTips() }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await refreshTips() }
            }
        }
    }
    
    /// Load all tips (uses cache-first, same query as the prefetcher → works offline)
    private func loadTips() async {
        isLoading = true
        errorMessage = nil
        
        do {
            allTips = try await TipService.shared.fetchTips(cityId: nil, limit: 500)
            displayedCount = min(pageSize, allTips.count)
        } catch {
            if allTips.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    /// Pull-to-refresh — force network fetch, keep old data as fallback
    private func refreshTips() async {
        let previousTips = allTips
        
        do {
            allTips = try await TipService.shared.fetchTips(cityId: nil, limit: 500, forceRefresh: true)
            displayedCount = min(pageSize, allTips.count)
        } catch {
            if allTips.isEmpty && !previousTips.isEmpty {
                allTips = previousTips
            }
        }
    }
}

// MARK: - Skeleton

struct TipItemSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(height: 14)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 200, height: 14)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 16))
        .redacted(reason: .placeholder)
    }
}

#Preview {
    NavigationStack {
        AllTipsListView()
    }
}
