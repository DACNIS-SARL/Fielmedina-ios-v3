//
//  Ads.swift
//  Fielmedina
//
//  Created by Aslan on 1/22/26.
//

import SwiftUI

struct AdsCarousel: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.openURL) private var openURL

    @State private var ads: [Advertisement] = []
    @State private var isLoading = true
    @State private var currentIndex = 0

    private var adHeight: CGFloat {
        sizeClass == .regular ? 90 : 50
    }

    private var adWidth: CGFloat {
        sizeClass == .regular ? 728 : 320
    }

    var body: some View {
        Group {
            if isLoading {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: adWidth, height: adHeight)
                    .padding(.horizontal, 16)
                    .redacted(reason: .placeholder)
            } else if ads.isEmpty {
                EmptyView()
            } else {
                VStack(spacing: 12) {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(ads.enumerated()), id: \.element.id) { index, ad in
                            Button {
                                openAd(ad)
                            } label: {
                                FielmedinaImage(url: ad.displayImage, contentMode: .fit)
                                    .frame(width: adWidth, height: adHeight)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: adHeight)
                    .padding(.horizontal, 16)
                }
            }
        }
        .task {
            await refreshAds()
        }
    }

    private func refreshAds() async {
        while !Task.isCancelled {
            await loadAds()
            await MainActor.run {
                if ads.count > 1 {
                    currentIndex = (currentIndex + 1) % ads.count
                } else {
                    currentIndex = 0
                }
            }
            try? await Task.sleep(for: .seconds(15))
        }
    }

    private func loadAds() async {
        let shouldShowLoading = ads.isEmpty
        if shouldShowLoading {
            isLoading = true
        }
        let previousAds = ads
        do {
            ads = try await AdService.shared.fetchAds(limit: 10)
        } catch {
            ads = previousAds
        }
        isLoading = false
    }

    private func openAd(_ ad: Advertisement) {
        guard let link = ad.resolvedLink, let url = URL(string: link) else {
            return
        }
        openURL(url)
    }
}

#Preview {
    AdsCarousel()
}
