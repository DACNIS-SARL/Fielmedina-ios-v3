//
//  MerchantCard.swift
//  Fielmedina
//
//  Created by Aslan on 6/2/26.
//

import SwiftUI

struct MerchantCardView: View {
    let merchant: Merchant
    let cardWidth: CGFloat = 320
    let cardHeight: CGFloat = 380
    
    var body: some View {
        ZStack(alignment: .bottom) {
            FielmedinaImage(url: merchant.imageURL, contentMode: .fill)
                .frame(width: cardWidth, height: cardHeight)
                .clipped()
            
            LinearGradient(
                colors: [.clear, .black.opacity(0.7), .black.opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )
            
            VStack {
                HStack {
                    if let category = merchant.category {
                        CategoryBadge(category: category)
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding(16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(merchant.displayName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let address = merchant.displayAddress {
                    Text(address)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(.rect(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}

private struct CategoryBadge: View {
    let category: MerchantCategory
    
    var body: some View {
        Text(category.displayName)
            .font(.caption.weight(.bold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground).opacity(0.95))
            .clipShape(.rect(cornerRadius: 12, style: .continuous))
    }
}
