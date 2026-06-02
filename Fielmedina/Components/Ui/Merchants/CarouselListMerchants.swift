//
//  CarouselListMerchants.swift
//  Fielmedina
//
//  Created by Aslan on 6/2/26.
//

import SwiftUI

struct CarouselListMerchants: View {
    @State private var merchants: [Merchant] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Merchants")
                .font(.title2.weight(.bold))
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
            } else if merchants.isEmpty {
                Text("No merchants found")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(merchants) { merchant in
                            NavigationLink(value: merchant) {
                                MerchantCardView(merchant: merchant)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .task {
            do {
                let fetched = try await MerchantService.shared.fetchMerchants(limit: 10)
                await MainActor.run {
                    self.merchants = fetched
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}
