import SwiftUI

struct CarouselListMerchants: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let isFeaturedOnly: Bool
    let limit: Int
    @Binding var refreshTrigger: Int
    
    @State private var merchants: [Merchant] = []
    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var isHorizontalRefreshing = false
    @State private var errorMessage: String?
    @State private var availableWidth: CGFloat = 0

    private let baseCardWidth: CGFloat = 320
    private let cardSpacing: CGFloat = 16
    private let horizontalInset: CGFloat = 20
    
    init(
        title: LocalizedStringKey = "Top Merchants",
        subtitle: LocalizedStringKey? = nil,
        isFeaturedOnly: Bool = false,
        limit: Int = 10,
        refreshTrigger: Binding<Int> = .constant(0)
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isFeaturedOnly = isFeaturedOnly
        self.limit = limit
        self._refreshTrigger = refreshTrigger
    }
    
    private var displayedMerchants: [Merchant] {
        let filtered = isFeaturedOnly ? merchants.filter { $0.isFeatured } : merchants
        return Array(filtered.prefix(limit))
    }

    private func cardWidth(for count: Int) -> CGFloat {
        guard count > 0, availableWidth > 0 else { return baseCardWidth }
        let usableWidth = availableWidth - horizontalInset * 2 - cardSpacing * CGFloat(count - 1)
        return max(baseCardWidth, usableWidth / CGFloat(count))
    }
    
    var body: some View {
        if isFeaturedOnly && !isLoading && displayedMerchants.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2.weight(.bold))
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                
                if isLoading {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 320, height: 380)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                } else if let error = errorMessage, !isFeaturedOnly {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            Task { await loadMerchants() }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if displayedMerchants.isEmpty && !isFeaturedOnly {
                    VStack(spacing: 12) {
                        Image(systemName: "storefront")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No merchants found")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            if isHorizontalRefreshing {
                                ProgressView()
                                    .padding(.leading, 16)
                                    .transition(.scale)
                            }
                            
                            let width = cardWidth(for: displayedMerchants.count)
                            ForEach(displayedMerchants) { merchant in
                                NavigationLink {
                                    MerchantDetailView(merchant: merchant)
                                } label: {
                                    MerchantCardView(merchant: merchant, cardWidth: width)
                                }
                            }
                        }
                        .padding(.horizontal, horizontalInset)
                    }
                    .onScrollGeometryChange(for: CGFloat.self, of: { geo in
                        return geo.contentOffset.x
                    }, action: { oldValue, newValue in
                        let threshold: CGFloat = 100
                        if newValue < -threshold && !isRefreshing && !isHorizontalRefreshing {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            isHorizontalRefreshing = true
                            Task {
                                await loadMerchants(forceRefresh: true)
                                isHorizontalRefreshing = false
                            }
                        }
                    })
                    .clipped()
                    .transition(.opacity.animation(.easeIn(duration: 0.3)))
                }
            }
            .animation(.easeIn(duration: 0.3), value: isLoading)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                availableWidth = width
            }
            .task {
                await loadMerchants()
            }
            .onChange(of: refreshTrigger) { _, _ in
                Task { await loadMerchants(forceRefresh: true) }
            }
        }
    }
    
    private func loadMerchants(forceRefresh: Bool = false) async {
        if forceRefresh {
            isRefreshing = true
        } else {
            isLoading = true
        }
        defer {
            isLoading = false
            isRefreshing = false
        }
        
        do {
            merchants = try await MerchantService.shared.fetchMerchants(
                limit: Int32(limit),
                forceRefresh: forceRefresh
            )
        } catch {
            if !forceRefresh {
                errorMessage = error.localizedDescription
            }
        }
    }
}
